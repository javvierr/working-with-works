module WorksHelper
  DISPLAY_TITLE_POLICY = "main_untyped_uniform_alternative_subordinate_v1".freeze
  # Exact whole-string explanations from the supplied public usability protocol.
  # See docs/final_submission/f3/F3_label_sources.md for authority and limits.
  INSTRUMENTATION_EXPLANATIONS = {
    "1 pf." => "one piano",
    "1 vl." => "one violin"
  }.freeze
  FILTER_LABELS = {
    "q" => "General search", "catalogue_number" => "Catalogue number",
    "instrumentation" => "Instrumentation", "genre" => "Genre",
    "year_from" => "Year from", "year_to" => "Year to",
    "page" => "Page", "per_page" => "Results per page"
  }.freeze

  def instrumentation_explanation(source_wording)
    INSTRUMENTATION_EXPLANATIONS.fetch(source_wording, "Explanation unavailable for this source wording.")
  end

  def work_catalogue_cue(work)
    identifiers = work.catalogue_identifiers.select { |identifier| identifier.identifier_type.present? && identifier.value.present? }
    identifier = identifiers.min_by do |candidate|
      type = candidate.identifier_type.strip
      [type.casecmp?("CNW") ? 0 : 1, type.downcase, candidate.value, candidate.id || 0]
    end
    if identifier
      type = identifier.identifier_type.strip
      value = identifier.value
      return "CNW #{value.sub(/\ACNW\s+/i, '')}" if type.casecmp?("CNW")

      return "#{type}: #{value}"
    end

    value = work.catalogue_number.presence
    return "Catalogue: Unknown" unless value
    if work.catalogue_document&.catalogue == "CNW"
      return "CNW #{value.sub(/\ACNW\s+/i, '')}"
    end

    "Catalogue: #{value}"
  end

  def works_filter_errors(parameter)
    @query.errors.select { |error| error[:parameter].to_s == parameter.to_s }
  end

  def works_filter_label(parameter)
    FILTER_LABELS.fetch(parameter.to_s, "Request parameter")
  end

  def works_filter_description(parameter, hint: false)
    [hint ? "#{parameter}-hint" : nil,
     works_filter_errors(parameter).any? ? "#{parameter}-error" : nil].compact.join(" ").presence
  end

  def works_page_label(relation)
    { "first" => "First page", "prev" => "Previous page", "next" => "Next page", "last" => "Last page" }.fetch(relation.to_s)
  end

  def work_projection(work)
    {
      titles: work.work_titles.map { |title| work_title_data(title, work) },
      classification_terms: work.work_classification_terms.map { |term| work_classification_data(term) },
      display_title_policy: work_display_title_policy(work),
      latest_import_attempt: work_import_attempt_data(work.latest_import_attempt),
      last_successful_import: work_successful_import_data(work.last_successful_import),
      availability: work_projection_availability(work),
      catalogue_sources: catalogue_sources_data(work)
    }
  end

  def work_title_data(title, work)
    {
      text: title.text,
      raw_text: title.raw_text,
      source_type: title.source_type,
      language: title.language,
      xml_id: title.xml_id,
      source_order: title.source_order,
      locator: title.locator,
      attributes: title.source_attributes,
      selected_for_display: title.source_order == work.display_title_order
    }
  end

  def work_classification_data(term)
    {
      text: term.text,
      raw_text: term.raw_text,
      xml_id: term.xml_id,
      source_order: term.source_order,
      locator: term.locator,
      attributes: term.source_attributes,
      classification_metadata: term.classification_metadata,
      term_list_metadata: term.term_list_metadata
    }
  end

  def work_projection_availability(work)
    document = work.catalogue_document
    return {
      status: "legacy_unvalidated",
      input_profile: nil,
      titles: "unvalidated",
      classification_terms: "unvalidated"
    } unless document

    {
      status: document.input_profile == "demo" ? "demo" : "official",
      input_profile: document.input_profile,
      titles: work.work_titles.empty? ? "missing" : "present",
      classification_terms: work.work_classification_terms.empty? ? "missing" : "present"
    }
  end

  def work_display_title_policy(work)
    return nil unless work.catalogue_document

    selected_title = work.work_titles.find { |title| title.source_order == work.display_title_order }
    {
      name: DISPLAY_TITLE_POLICY,
      selection_reason: work.display_title_reason,
      source_order: work.display_title_order,
      xml_id: selected_title&.xml_id,
      subordinate_fallback: selected_title&.source_type == "subordinate"
    }
  end

  def work_import_attempt_data(attempt)
    return nil unless attempt

    {
      id: attempt.id,
      status: attempt.status,
      imported_at: attempt.imported_at,
      error_message: attempt.safe_error_message,
      warnings: attempt.safe_warnings,
      attempted_profile: attempt.attempted_profile,
      attempted_catalogue: attempt.attempted_catalogue,
      attempted_record_key: attempt.attempted_record_key,
      attempted_sha256: attempt.attempted_sha256,
      previous_committed_sha256: attempt.previous_committed_sha256
    }
  end

  def work_successful_import_data(attempt)
    return nil unless attempt

    {
      id: attempt.id,
      imported_at: attempt.imported_at,
      input_profile: attempt.attempted_profile,
      catalogue: attempt.attempted_catalogue,
      record_key: attempt.attempted_record_key,
      committed_sha256: attempt.attempted_sha256
    }
  end

  def catalogue_sources_data(work)
    document = work.catalogue_document
    identity = document&.attributes&.slice("input_profile", "catalogue", "record_key", "root_xml_id", "committed_sha256")
    version = document&.source_projection_version
    current = version == "cnw_sources_v1" && document.source_projection_summary.is_a?(Hash)
    {
      "document" => identity,
      "projection" => { "version" => version, "summary" => current ? document.source_projection_summary : { "state" => "not_projected" } },
      "descriptions" => current ? document.source_descriptions.map { |source| catalogue_source_data(source) } : []
    }
  end

  def catalogue_source_data(source)
    source.attributes.slice("xml_id", "locator", "source_order", "label", "parent_metadata", "state",
      "identifiers", "titles", "classification_terms", "publication", "physical_description", "notes", "links", "availability").merge(
      "attributes" => source.source_attributes,
      "relations" => source.source_relations.map { |relation| catalogue_relation_data(relation, source.xml_id) },
      "held_items" => source.held_items.map { |item| catalogue_item_data(item, source.xml_id) }
    )
  end

  def catalogue_item_data(item, source_xml_id)
    item.attributes.slice("xml_id", "locator", "source_order", "label", "parent_metadata", "state",
      "identifiers", "physical_locations", "physical_description", "links", "availability").merge(
      "source_xml_id" => source_xml_id, "attributes" => item.source_attributes
    )
  end

  def catalogue_relation_data(relation, source_xml_id)
    relation.attributes.slice("xml_id", "locator", "relation_order", "token_order", "rel", "raw_target", "target_token",
      "parent_metadata", "resolution_state", "resolution_reason", "expression_context").merge(
      "source_xml_id" => source_xml_id,
      "attributes" => relation.source_attributes,
      "target_source_xml_id" => relation.target_source_description&.xml_id
    )
  end

  def catalogue_source_heading(source)
    source.fetch("titles").filter_map { |title| title["text"].presence }.first || source["label"].presence || "Untitled source description"
  end

  def catalogue_source_anchor(xml_id)
    "catalogue-source-#{Digest::SHA256.hexdigest(xml_id)}"
  end

  def catalogue_node_state(state)
    {
      "descriptive" => "Descriptive content supplied",
      "label_or_link_stub" => "Label or link only; descriptive content not supplied",
      "empty_placeholder" => "Empty placeholder; this does not establish a held copy or location"
    }.fetch(state, "State not supplied")
  end
end
