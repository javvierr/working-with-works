# frozen_string_literal: true

require "digest"
require "nokogiri"
require "pathname"

module Mei
  # Validates the bounded input profile before any catalogue facts are written.
  # XML IDs identify nodes within this document, never global catalogue records.
  class InputDocument
    MEI_NAMESPACE = "http://www.music-encoding.org/ns/mei"
    XML_NAMESPACE = "http://www.w3.org/XML/1998/namespace"
    PROFILES = %w[official_cnw_v401 demo].freeze
    TITLE_RANKS = { "main" => 0, "untyped" => 1, "uniform" => 2, "alternative" => 3, "subordinate" => 4 }.freeze

    class Invalid < StandardError; end

    attr_reader :path, :origin_relative_name, :observed_path, :input_profile,
      :sha256, :document, :work, :namespace, :identity, :raw_record_identifier,
      :identifier_attributes, :error

    def initialize(path:, directory:, input_profile:, fixture_key: nil)
      @path = Pathname.new(path)
      @origin_relative_name = @path.relative_path_from(Pathname.new(directory)).to_s
      @input_profile = input_profile
      @fixture_key = fixture_key
      @observed_path = @path.realpath.to_s
    rescue SystemCallError
      @observed_path = @path.expand_path.to_s
    end

    def read
      bytes = path.binread
      @sha256 = Digest::SHA256.hexdigest(bytes)
      @document = Nokogiri::XML::Document.parse(bytes, nil, nil, Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NONET)
      raise Invalid, "DTD and entity declarations are unsupported" if document.internal_subset || document.external_subset
      root = document.root
      raise Invalid, "Expected an MEI root element" unless root&.name == "mei"
      @namespace = root.namespace&.href
      if input_profile == "official_cnw_v401"
        raise Invalid, "Official input requires the MEI namespace" unless namespace == MEI_NAMESPACE
        raise Invalid, "Official input requires MEI version 4.0.1" unless root["meiversion"] == "4.0.1"
      elsif input_profile == "demo"
        raise Invalid, "Demo input requires MEI or no namespace" unless [nil, MEI_NAMESPACE].include?(namespace)
        raise Invalid, "Demo input requires an explicit stable fixture key" if xml_space(@fixture_key).empty?
      else
        raise Invalid, "Unsupported input profile"
      end
      ids = document.xpath("//*[@xml:id]", "xml" => XML_NAMESPACE).map { |node| node["xml:id"] }
      raise Invalid, "Duplicate document-local XML ID" unless ids.uniq.length == ids.length
      works = nodes(document, "/mei/meiHead/workList/work")
      raise Invalid, "Expected exactly one direct MEI work" unless works.length == 1
      @work = works.first
      extract_identity!
      self
    rescue Nokogiri::XML::SyntaxError
      @error = Invalid.new("Malformed XML")
      self
    rescue SystemCallError, IOError
      @error = Invalid.new("Source file could not be read")
      self
    rescue Invalid => failure
      @error = failure
      self
    end

    def valid? = error.nil? && identity.present?

    def xml_space(value)
      value.to_s.gsub(/[\x20\x09\x0D\x0A]+/, " ").sub(/\A /, "").sub(/ \z/, "")
    end

    # The existing extraction paths only use child/descendant steps and unions.
    # Qualify those element steps rather than stripping source namespaces.
    def nodes(node, expression)
      qualified = namespace ? expression.gsub(%r{(?<=/)([A-Za-z_][\w.-]*)}, 'm:\1') : expression
      node.xpath(qualified, "m" => MEI_NAMESPACE, "xml" => XML_NAMESPACE)
    end

    def first(node, expression) = nodes(node, expression).first

    def attributes(node)
      node.attribute_nodes.to_h do |attribute|
        uri = attribute.namespace&.href
        [uri ? "{#{uri}}#{attribute.name}" : attribute.name, attribute.value]
      end
    end

    def locator(node)
      (node.ancestors.select(&:element?).reverse + [node]).map do |part|
        siblings = part.parent&.element_children&.select { |sibling| sibling.name == part.name && sibling.namespace&.href == part.namespace&.href } || [part]
        prefix = part.namespace&.href == MEI_NAMESPACE ? "m:" : ""
        "/#{prefix}#{part.name}[#{siblings.index(part) + 1}]"
      end.join
    end

    def title_rows
      nodes(work, "./title").each_with_index.filter_map do |node, index|
        text = xml_space(node.text)
        next if text.empty?
        { text: text, raw_text: node.text, source_type: node["type"], language: node["xml:lang"],
          xml_id: node["xml:id"], source_order: index + 1, locator: locator(node), source_attributes: attributes(node) }
      end
    end

    def heading(titles)
      eligible = titles.filter_map do |row|
        raw_type = row[:source_type]
        kind = xml_space(raw_type).empty? ? "untyped" : raw_type
        rank = TITLE_RANKS[kind]
        [rank, row[:source_order], kind, row] if rank
      end
      selected = eligible.min_by { |rank, order, _kind, _row| [rank, order] }
      raise Invalid, "No eligible nonblank direct work title" unless selected
      { row: selected[3], reason: selected[2] }
    end

    def classification_rows
      rows = []
      nodes(work, "./classification").each do |classification|
        nodes(classification, ".//term").each do |term|
          ancestors = term.ancestors.take_while { |ancestor| ancestor != classification }
          forbidden = %w[work expression manifestation item source bibl biblList event classification]
          next if ancestors.any? { |ancestor| forbidden.include?(ancestor.name) }
          text = xml_space(term.text)
          next if text.empty?
          lists = ancestors.select { |ancestor| ancestor.name == "termList" }.reverse
          rows << { text: text, raw_text: term.text, xml_id: term["xml:id"], source_order: rows.length + 1,
            locator: locator(term), source_attributes: attributes(term),
            classification_metadata: metadata(classification), term_list_metadata: lists.map { |node| metadata(node) } }
        end
      end
      rows
    end

    private

    def metadata(node)
      { "locator" => locator(node), "attributes" => attributes(node) }
    end

    def extract_identity!
      if input_profile == "demo"
        @raw_record_identifier = @fixture_key.to_s
        @identifier_attributes = {}
        @identity = { input_profile: "demo", catalogue: "demo", record_key: xml_space(@fixture_key) }
        return
      end
      candidates = nodes(work, "./identifier").select do |node|
        labels = [node["label"], node["type"]].filter_map { |value| xml_space(value).presence }
        matching = labels.any? { |value| value.casecmp?("CNW") }
        raise Invalid, "Conflicting CNW identifier family markers" if matching && labels.any? { |value| !value.casecmp?("CNW") }
        matching
      end
      raise Invalid, "Expected exactly one direct CNW identifier" unless candidates.length == 1
      identifier = candidates.first
      @raw_record_identifier = identifier.text
      key = xml_space(raw_record_identifier)
      raise Invalid, "CNW record identifier is blank" if key.empty?
      @identifier_attributes = attributes(identifier)
      @identity = { input_profile: input_profile, catalogue: "CNW", record_key: key }
    end
  end
end
