require "date"
require "nokogiri"
require "pathname"

module Mei
  class Importer
    Result = Struct.new(:files_seen, :successes, :failures, :warnings, keyword_init: true) do
      def initialize(**)
        super(files_seen: 0, successes: 0, failures: 0, warnings: [], **)
      end
    end

    def initialize(directory: Rails.root.join("data/mei_samples"))
      @directory = Pathname.new(directory)
    end

    def call
      result = Result.new
      files.each do |path|
        result.files_seen += 1
        import_file(path, result)
      end
      result.warnings << "No XML or MEI files found in #{@directory}" if result.files_seen.zero?
      result
    end

    private

    attr_reader :directory

    def files
      Dir.glob(directory.join("**", "*.{xml,mei}")).sort.map { |path| Pathname.new(path) }
    end

    def import_file(path, result)
      source_file = relative_path(path)
      warnings = []
      extracted_title = nil

      ActiveRecord::Base.transaction do
        doc = parse_document(path, warnings)
        extracted = extract(doc, source_file, warnings)
        extracted_title = extracted[:work][:title]

        composer = Composer.find_or_create_by!(name: extracted[:composer_name])
        work = Work.find_or_initialize_by(source_file: source_file)
        work.assign_attributes(extracted[:work].merge(composer: composer))
        work.save!

        replace_children(work, extracted)
        ImportLog.create!(
          work: work,
          source_file: source_file,
          status: "success",
          work_title: work.title,
          warnings: warnings,
          imported_at: Time.current
        )
      end

      result.successes += 1
      result.warnings.concat(warnings)
    rescue StandardError => error
      result.failures += 1
      result.warnings.concat(warnings)
      ImportLog.create!(
        source_file: source_file,
        status: "failure",
        work_title: extracted_title,
        warnings: warnings,
        error_message: error.message,
        imported_at: Time.current
      )
    end

    def parse_document(path, warnings)
      doc = Nokogiri::XML(path.read) do |config|
        config.recover.nonet.noblanks
      end
      warnings.concat(doc.errors.map { |error| "XML parser warning: #{error.message.strip}" }) if doc.errors.any?

      # MEI records commonly use a default namespace. Removing namespaces keeps
      # the prototype parser tolerant of both namespaced and simple fixture XML.
      doc.remove_namespaces!
      doc
    end

    def extract(doc, source_file, warnings)
      work_node = doc.at_xpath("//work") || doc.root
      composer_name = composer_name_for(doc, work_node)
      if composer_name.blank?
        composer_name = "Unknown composer"
        warnings << "Missing composer; imported as Unknown composer"
      end

      title = first_text(work_node, [
        "./title[@type='main']",
        "./title[@type='uniform']",
        "./title[1]",
        ".//title[@type='main']",
        ".//title[1]"
      ]) || first_text(doc, ["//titleStmt/title[@type='main']", "//titleStmt/title[1]"])
      warnings << "Missing work title" if title.blank?

      identifiers = catalogue_identifiers(work_node, warnings)
      catalogue_number = catalogue_number_for(work_node, identifiers)
      date_node = first_node(work_node, [
        "./creation/date",
        "./date[@type='composition']",
        "./date[@label='composition']"
      ])
      composition_date = normalize(date_node&.text)
      composition_year = extract_year(date_node)
      warnings << "Missing composition date or year" if composition_date.blank? && composition_year.blank?

      genre = first_text(work_node, [
        ".//classification//term[@type='genre']",
        ".//term[@type='genre']",
        ".//genre",
        ".//classification//term[1]"
      ])
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
          source_identifier: work_node["id"] || work_node["xml:id"] || doc.root&.[]("id")
        },
        catalogue_identifiers: identifiers,
        movements: movements(work_node, warnings),
        instrumentations: instrumentations(work_node, warnings),
        source_references: source_references(doc, work_node, warnings),
        performances: performances(work_node, warnings),
        external_references: external_references(work_node, warnings)
      }
    end

    def composer_name_for(doc, work_node)
      direct_contributor_name = work_node.xpath("./contributor//persName").filter_map do |node|
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
      nodes = work_node.xpath("./identifier | ./idno")
      nodes = work_node.xpath(".//identifier | .//idno") if nodes.empty?
      rows = identifier_rows(nodes)
      warnings << "Missing catalogue identifier" if rows.empty?
      rows
    end

    def catalogue_number_for(work_node, identifiers)
      direct_cnw_identifier = identifier_rows(work_node.xpath("./identifier | ./idno")).find do |identifier|
        identifier[:identifier_type].casecmp?("CNW")
      end

      (direct_cnw_identifier || identifiers.first)&.fetch(:value, nil)
    end

    def identifier_rows(nodes)
      nodes.map do |node|
        value = normalize(node.text)
        next if value.blank?

        {
          identifier_type: normalize(node["type"] || node["label"]) || "catalogue",
          value: value
        }
      end.compact.uniq { |row| [row[:identifier_type], row[:value]] }
    end

    def movements(work_node, warnings)
      nodes = work_node.xpath(".//contents//mdiv | .//movement")
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
      nodes = work_node.xpath(".//perfMedium//perfRes | .//instrumentation//instrument | .//instrument")
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
      nodes = doc.xpath("//sourceDesc//source") + work_node.xpath(".//sourceList//source")
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
        date_node = node.at_xpath("./date")
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
      event_nodes = work_node.xpath(".//eventList/event").select do |event|
        list_type = normalize(event.parent["type"])
        event_type = normalize(event["type"])

        list_type&.casecmp?("performances") ||
          %w[firstperformance performance].include?(event_type&.downcase)
      end

      event_nodes + work_node.xpath(".//performance").to_a
    end

    def performance_location(node)
      node.xpath("./geogName | ./placeName | ./location").filter_map do |location_node|
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
      node.xpath("./persName | ./corpName").filter_map do |name_node|
        name = normalize(name_node.text)
        next if name.blank?

        role = normalize(name_node["role"])
        role.present? ? "#{name} (#{role})" : name
      end.join(", ").presence
    end

    def performance_note(node)
      ["./desc", "./description", "./note"].filter_map do |xpath|
        normalize(node.at_xpath(xpath)&.text)
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
      nodes = work_node.xpath(".//relation[@target] | .//ref[@target] | .//ptr[@target]")
      rows = nodes.map do |node|
        url = normalize(node["target"])
        next if url.blank?

        {
          label: first_text(node, ["./label"]) || normalize(node.text) || normalize(node["rel"]) || "External reference",
          url: url
        }
      end.compact.uniq { |row| row[:url] }
      warnings << "No external references found" if rows.empty?
      rows
    end

    def first_node(node, xpaths)
      xpaths.lazy.map { |xpath| node.at_xpath(xpath) }.find(&:present?)
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
