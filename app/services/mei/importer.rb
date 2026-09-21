require "date"
require "nokogiri"
require "pathname"
require "uri"

module Mei
  class Importer
    Result = Struct.new(:files_seen, :successes, :failures, :warnings, :run_errors, keyword_init: true) do
      def initialize(**)
        super(files_seen: 0, successes: 0, failures: 0, warnings: [], run_errors: [], **)
      end

      def success? = files_seen.positive? && failures.zero? && run_errors.empty?
    end

    def initialize(directory: Rails.root.join("data/mei_samples"), input_profile: "official_cnw_v401", fixture_key: nil, fixture_keys: {})
      raise ArgumentError, "Unsupported input profile" unless InputDocument::PROFILES.include?(input_profile)
      raise ArgumentError, "Use fixture_key or fixture_keys, not both" if fixture_key && fixture_keys.any?
      @directory = Pathname.new(directory).expand_path
      @input_profile = input_profile
      @fixture_key = fixture_key
      @fixture_keys = fixture_keys.stringify_keys
    end

    def call
      result = Result.new
      unless directory.directory?
        result.run_errors << "Input directory does not exist"
        return result
      end
      paths = files
      if paths.empty?
        result.run_errors << "Input directory contains no XML or MEI files"
        return result
      end
      inputs = paths.map do |path|
        key = paths.one? ? @fixture_key : nil
        key ||= @fixture_keys[path.relative_path_from(directory).to_s]
        InputDocument.new(path: path, directory: directory, input_profile: @input_profile, fixture_key: key).read
      end
      # Inventory the whole batch first: no first-file-wins identity collisions.
      collisions = inputs.select(&:valid?).group_by(&:identity).select { |_key, members| members.length > 1 }.keys
      result.files_seen = inputs.length
      inputs.each do |input|
        import_file(input, result, duplicate: collisions.include?(input.identity))
      end
      result
    end

    private

    attr_reader :directory

    def files
      Dir.glob(directory.join("**", "*.{xml,mei}")).sort.map { |path| Pathname.new(path) }
    end

    def import_file(input, result, duplicate: false)
      source_file = relative_path(input.path)
      warnings = []
      extracted_title = nil
      @input = input
      raise input.error if input.error
      raise InputDocument::Invalid, "Duplicate logical identity in input batch; all colliding inputs rejected" if duplicate
      extracted = extract(input.document, source_file, warnings)
      extracted_title = extracted[:work][:title]
      source_projection = SourceProjection.new(input).call

      ActiveRecord::Base.transaction do
        catalogue_document = checked_document(input)
        catalogue_document.lock! if catalogue_document.persisted?
        old_hash = catalogue_document.committed_sha256
        old_root_id = catalogue_document.root_xml_id
        old_projection_version = catalogue_document.source_projection_version
        work = catalogue_document.work
        old_work_id = work&.source_identifier
        unchanged = catalogue_document.persisted? && old_hash == input.sha256
        project_sources = !unchanged || old_projection_version != SourceProjection::VERSION
        raise InputDocument::Invalid, "Existing validated document has no work" if unchanged && work.nil?
        now = Time.current
        unless unchanged
          catalogue_document.assign_attributes(
            input.identity.merge(raw_record_identifier: input.raw_record_identifier,
              identifier_attributes: input.identifier_attributes, root_xml_id: input.document.root["xml:id"],
              mei_namespace: input.namespace, mei_version: input.document.root["meiversion"],
              committed_sha256: input.sha256,
              origin_relative_name: catalogue_document.origin_relative_name || input.origin_relative_name)
          )
        end
        catalogue_document.assign_attributes(latest_successful_path: input.observed_path, last_successful_at: now)
        catalogue_document.save!
        unless unchanged
          composer = Composer.find_or_create_by!(name: extracted[:composer_name])
          work ||= Work.new(catalogue_document: catalogue_document)
          work.assign_attributes(extracted[:work].merge(composer: composer))
          work.save!
          replace_children(work, extracted)
        end
        if project_sources
          replace_source_projection(catalogue_document, work, source_projection)
          catalogue_document.update!(source_projection_version: source_projection.fetch("version"),
            source_projection_summary: source_projection.fetch("summary"))
        end
        ImportLog.create!(
          work: work,
          catalogue_document: catalogue_document,
          source_file: source_file,
          status: "success",
          work_title: work.title,
          warnings: warnings,
          imported_at: now,
          **attempt_attributes(input, previous_hash: old_hash),
          provenance: { old_root_xml_id: old_root_id, new_root_xml_id: input.document.root["xml:id"],
            old_work_xml_id: old_work_id, new_work_xml_id: input.work["xml:id"],
            unchanged_bytes: unchanged, origin_relative_name: input.origin_relative_name,
            old_source_projection_version: old_projection_version, new_source_projection_version: catalogue_document.source_projection_version,
            projection_version_changed: old_projection_version != catalogue_document.source_projection_version,
            source_projection_updated: project_sources }
        )
      end

      result.successes += 1
      result.warnings.concat(warnings)
    rescue StandardError => error
      result.failures += 1
      result.warnings.concat(warnings)
      # A rolled-back in-memory record is not evidence of a surviving identity.
      # Resolve afresh, preferring successful path ownership over attempted key.
      catalogue_document = failure_document(input)
      ImportLog.create!(
        catalogue_document: catalogue_document,
        work: catalogue_document&.work,
        source_file: source_file,
        status: "failure",
        work_title: extracted_title,
        warnings: warnings,
        error_message: safe_error(error),
        imported_at: Time.current,
        **attempt_attributes(input, previous_hash: catalogue_document&.committed_sha256),
        provenance: { origin_relative_name: input.origin_relative_name,
          association_basis: catalogue_document ? "successful_path_or_valid_identity" : "unresolved",
          previous_source_projection_version: catalogue_document&.source_projection_version,
          attempted_source_projection_version: SourceProjection::VERSION }
      )
    end

    def replace_source_projection(document, work, projection)
      sources = document.source_descriptions
      items = document.held_items
      # Edges may be cyclic and may target sources removed by this replacement.
      # Remove only this document's edges before touching any target rows.
      document.source_relations.delete_all
      descriptions = projection.fetch("descriptions")
      reserve_projection_ordinals(sources, incoming_orders: descriptions.map { |row| row.fetch("source_order") })
      reserve_projection_ordinals(items, incoming_orders: descriptions.flat_map { |row| row.fetch("held_items").map { |item| item.fetch("source_order") } })
      source_by_xml_id = sources.index_by(&:xml_id)
      item_by_xml_id = items.index_by(&:xml_id)
      retained_source_ids = []
      retained_item_ids = []

      projection.fetch("descriptions").each do |row|
        source = source_by_xml_id[row.fetch("xml_id")] || sources.new
        source.assign_attributes(projection_attributes(row, except: %w[held_items relations]))
        source.save!
        source_by_xml_id[row.fetch("xml_id")] = source
        retained_source_ids << source.id
      end

      projection.fetch("descriptions").each do |row|
        source = source_by_xml_id.fetch(row.fetch("xml_id"))
        row.fetch("held_items").each do |item_row|
          item = item_by_xml_id[item_row.fetch("xml_id")] || items.new
          item.assign_attributes(projection_attributes(item_row, except: %w[source_xml_id]).merge(source_description: source))
          item.save!
          retained_item_ids << item.id
        end
      end
      items.where.not(id: retained_item_ids).destroy_all
      sources.where.not(id: retained_source_ids).destroy_all

      projection.fetch("descriptions").each do |row|
        source = source_by_xml_id.fetch(row.fetch("xml_id"))
        row.fetch("relations").each do |relation_row|
          target_id = relation_row.fetch("target_source_xml_id")
          attributes = projection_attributes(relation_row, except: %w[source_xml_id target_source_xml_id])
          attributes["source_description"] = source
          attributes["target_source_description"] = source_by_xml_id.fetch(target_id) if target_id
          attributes["target_work"] = work if relation_row.fetch("resolution_state") == "resolved_expression"
          document.source_relations.create!(attributes)
        end
      end
    end

    def reserve_projection_ordinals(scope, incoming_orders:)
      records = scope.reorder(:id).to_a
      offset = [records.map(&:source_order).max.to_i, incoming_orders.max.to_i].max + records.length + 1
      records.each_with_index { |record, index| record.update_columns(source_order: offset + index) }
    end

    def projection_attributes(row, except:)
      row.except("attributes", *except).merge("source_attributes" => row.fetch("attributes"))
    end

    def successful_path_owners(input)
      ImportLog.where(status: "success", observed_path: input.observed_path)
        .where.not(catalogue_document_id: nil).distinct.pluck(:catalogue_document_id)
    end

    def checked_document(input)
      owners = successful_path_owners(input)
      raise InputDocument::Invalid, "Successful source path ownership is ambiguous" if owners.length > 1
      document = CatalogueDocument.find_by(input.identity)
      if owners.any? && owners.first != document&.id
        raise InputDocument::Invalid, "Source path already belongs to another catalogue identity"
      end
      if document && document.committed_sha256 != input.sha256 && owners.exclude?(document.id)
        raise InputDocument::Invalid, "Changed bytes at an unrecognized path conflict with the existing identity"
      end
      document || CatalogueDocument.new(input.identity)
    end

    def failure_document(input)
      owners = successful_path_owners(input)
      return CatalogueDocument.find_by(id: owners.first) if owners.one?
      return if owners.any? || !input.valid?

      CatalogueDocument.find_by(input.identity)
    end

    def attempt_attributes(input, previous_hash:)
      { attempted_profile: input.input_profile, attempted_catalogue: input.identity&.fetch(:catalogue),
        attempted_record_key: input.identity&.fetch(:record_key), attempted_sha256: input.sha256,
        previous_committed_sha256: previous_hash, observed_path: input.observed_path }
    end

    def safe_error(error)
      case error
      when InputDocument::Invalid then error.message.first(500)
      when ActiveRecord::RecordInvalid then "Imported record failed persistence validation"
      when ActiveRecord::StatementInvalid then "Database constraint rejected the imported record"
      else "Import failed (#{error.class.name})".first(500)
      end
    end

    def extract(doc, source_file, warnings)
      work_node = @input.work
      composer_name = composer_name_for(doc, work_node)
      if composer_name.blank?
        composer_name = "Unknown composer"
        warnings << "Missing composer; imported as Unknown composer"
      end

      titles = @input.title_rows
      heading = @input.heading(titles)
      title = heading[:row][:text]

      identifiers = catalogue_identifiers(work_node, warnings)
      catalogue_number = @input.input_profile == "official_cnw_v401" ? @input.identity.fetch(:record_key) : catalogue_number_for(work_node, identifiers)
      date_node = first_node(work_node, [
        "./creation/date",
        "./date[@type='composition']",
        "./date[@label='composition']"
      ])
      composition_date = normalize(date_node&.text)
      composition_year = extract_year(date_node)
      warnings << "Missing composition date or year" if composition_date.blank? && composition_year.blank?

      terms = @input.classification_rows
      genre = terms.first&.fetch(:text)
      warnings << "Missing genre/category" if genre.blank?

      {
        composer_name: composer_name,
        work: {
          title: title,
          catalogue_number: catalogue_number,
          composition_date: composition_date,
          composition_year: composition_year,
          genre: genre,
          source_file: source_file,
          source_identifier: work_node["xml:id"] || work_node["id"],
          display_title_reason: "#{heading[:reason]}/source_order; no language preference", display_title_order: heading[:row][:source_order]
        },
        work_titles: titles,
        work_classification_terms: terms,
        catalogue_identifiers: identifiers,
        movements: movements(work_node, warnings),
        instrumentations: instrumentations(work_node, warnings),
        source_references: source_references(doc, work_node, warnings),
        performances: performances(work_node, warnings),
        external_references: external_references(work_node, warnings)
      }
    end

    def composer_name_for(doc, work_node)
      direct_contributor_name = source_nodes(work_node, "./contributor//persName").filter_map do |node|
        next unless normalize(node["role"])&.casecmp?("composer")

        normalize(node.text)
      end.first

      direct_contributor_name ||
        first_text(work_node, ["./composer//persName", "./composer"]) ||
        first_text(doc.root, [
          "./meiHead/fileDesc/titleStmt/composer/persName",
          "./meiHead/fileDesc/titleStmt/composer"
        ])
    end

    def replace_children(work, extracted)
      {
        work_titles: WorkTitle,
        work_classification_terms: WorkClassificationTerm,
        catalogue_identifiers: CatalogueIdentifier,
        movements: Movement,
        instrumentations: Instrumentation,
        source_references: SourceReference,
        performances: Performance,
        external_references: ExternalReference
      }.each_key do |association|
        work.public_send(association).destroy_all
        extracted[association].each { |attributes| work.public_send(association).create!(attributes) }
      end
    end

    def catalogue_identifiers(work_node, warnings)
      nodes = source_nodes(work_node, "./identifier | ./idno")
      nodes = source_nodes(work_node, ".//identifier | .//idno") if nodes.empty?
      rows = identifier_rows(nodes)
      warnings << "Missing catalogue identifier" if rows.empty?
      rows
    end

    def catalogue_number_for(work_node, identifiers)
      direct_cnw_identifier = identifier_rows(source_nodes(work_node, "./identifier | ./idno")).find do |identifier|
        identifier[:identifier_type].casecmp?("CNW")
      end

      (direct_cnw_identifier || identifiers.first)&.fetch(:value, nil)
    end

    def identifier_rows(nodes)
      nodes.map do |node|
        value = normalize(node.text)
        next if value.blank?

        {
          identifier_type: normalize(node["type"]) || normalize(node["label"]) || "catalogue",
          value: value
        }
      end.compact.uniq { |row| [row[:identifier_type], row[:value]] }
    end

    def movements(work_node, warnings)
      nodes = source_nodes(work_node, ".//contents//mdiv | .//movement")
      rows = nodes.each_with_index.map do |node, index|
        title = first_text(node, ["./head", "./title", "./label"]) || normalize(node.text)
        next if title.blank?

        {
          position: (node["n"] || node["position"] || index + 1).to_i,
          title: title,
          tempo_marking: first_text(node, [".//tempo", ".//term[@type='tempo']"]),
          duration: first_text(node, [".//duration", ".//dur"])
        }
      end.compact
      warnings << "No movements found" if rows.empty?
      rows
    end

    def instrumentations(work_node, warnings)
      nodes = source_nodes(work_node, ".//perfMedium//perfRes | .//instrumentation//instrument | .//instrument")
      rows = nodes.map do |node|
        name = normalize(node.text)
        next if name.blank?

        count = normalize(node["count"])
        name = "#{count} #{name}" if count.present? && !name.start_with?(count)
        {
          name: name,
          section: normalize(node["section"] || node.parent&.[]("label") || node.parent&.name)
        }
      end.compact.uniq { |row| row[:name].downcase }
      warnings << "No instrumentation found" if rows.empty?
      rows
    end

    def source_references(doc, work_node, warnings)
      nodes = source_nodes(doc, "//sourceDesc//source") + source_nodes(work_node, ".//sourceList//source")
      rows = nodes.map do |node|
        label = first_text(node, ["./title", ".//title", "./identifier", ".//identifier"])
        description = first_text(node, ["./physDesc", ".//physDesc", "./bibl", ".//bibl"])
        next if label.blank? && description.blank?

        {
          label: label || "Source",
          source_type: normalize(node["type"] || node["label"]),
          description: description,
          repository: first_text(node, ["./repository", ".//repository", "./repository//corpName", ".//repository//corpName"])
        }
      end.compact.uniq { |row| [row[:label], row[:description]] }
      warnings << "No source references found" if rows.empty?
      rows
    end

    def performances(work_node, warnings)
      nodes = performance_nodes(work_node)
      if nodes.empty?
        warnings << "No performance information found"
        return []
      end

      nodes.filter_map do |node|
        date_node = source_node(node, "./date")
        performed_on = parse_date(date_node)
        non_exact_date = performance_date_present?(date_node) && performed_on.blank?

        location = performance_location(node)
        performers = performance_performers(node)
        note = performance_note(node)
        if performed_on.blank? && location.blank? && performers.blank? && note.blank?
          warnings << "Skipped performance event with no supported direct values"
          next
        end

        warnings << "Non-exact performance date was not stored" if non_exact_date

        {
          performed_on: performed_on,
          location: location,
          performers: performers,
          note: note
        }
      end
    end

    def performance_nodes(work_node)
      event_nodes = source_nodes(work_node, ".//eventList/event").select do |event|
        list_type = normalize(event.parent["type"])
        event_type = normalize(event["type"])

        list_type&.casecmp?("performances") ||
          %w[firstperformance performance].include?(event_type&.downcase)
      end

      event_nodes + source_nodes(work_node, ".//performance").to_a
    end

    def performance_location(node)
      source_nodes(node, "./geogName | ./placeName | ./location").filter_map do |location_node|
        value = normalize(location_node.text)
        next if value.blank?

        case normalize(location_node["role"])&.downcase
        when "venue"
          "Venue: #{value}"
        when "place"
          "Place: #{value}"
        else
          value
        end
      end.join("; ").presence
    end

    def performance_performers(node)
      source_nodes(node, "./persName | ./corpName").filter_map do |name_node|
        name = normalize(name_node.text)
        next if name.blank?

        role = normalize(name_node["role"])
        role.present? ? "#{name} (#{role})" : name
      end.join(", ").presence
    end

    def performance_note(node)
      ["./desc", "./description", "./note"].filter_map do |xpath|
        normalize(source_node(node, xpath)&.text)
      end.first
    end

    def performance_date_present?(date_node)
      return false if date_node.blank?

      [
        date_node["isodate"],
        date_node["notbefore"],
        date_node["notafter"],
        date_node["startdate"],
        date_node["enddate"],
        date_node.text
      ].any? { |value| normalize(value).present? }
    end

    def external_references(work_node, warnings)
      nodes = source_nodes(work_node, ".//relation[@target] | .//ref[@target] | .//ptr[@target]")
      rows = nodes.map do |node|
        url = normalize(node["target"])
        next unless absolute_http_reference?(url)

        {
          label: first_text(node, ["./label"]) || normalize(node.text) || normalize(node["rel"]) || "External reference",
          url: url
        }
      end.compact.uniq { |row| row[:url] }
      warnings << "No external references found" if rows.empty?
      rows
    end

    def absolute_http_reference?(target)
      return false if target.blank?

      uri = URI.parse(target)

      %w[http https].include?(uri.scheme&.downcase) && uri.host.present?
    rescue URI::Error
      false
    end

    def source_nodes(node, xpath) = @input.nodes(node, xpath)

    def source_node(node, xpath) = @input.first(node, xpath)

    def first_node(node, xpaths)
      xpaths.lazy.map { |xpath| source_node(node, xpath) }.find(&:present?)
    end

    def first_text(node, xpaths)
      first_node(node, xpaths)&.text&.then { |text| normalize(text) }
    end

    def normalize(value)
      value.to_s.squish.presence
    end

    def extract_year(date_node)
      return if date_node.blank?

      [
        date_node["isodate"],
        date_node["notbefore"],
        date_node["notafter"],
        date_node.text
      ].compact.join(" ")[/\b(\d{4})\b/, 1]&.to_i
    end

    def parse_date(date_node)
      return if date_node.blank?
      return if %w[notbefore notafter startdate enddate].any? { |attribute| normalize(date_node[attribute]).present? }

      [date_node["isodate"], date_node.text].filter_map { |value| normalize(value) }.each do |value|
        next unless value.match?(/\A\d{4}-\d{2}-\d{2}\z/)

        begin
          return Date.iso8601(value)
        rescue Date::Error
          next
        end
      end

      nil
    end

    def relative_path(path)
      path.relative_path_from(Rails.root).to_s
    rescue ArgumentError
      path.to_s
    end
  end
end
