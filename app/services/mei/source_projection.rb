# frozen_string_literal: true

module Mei
  # A bounded, document-local projection. No persistence, fetching or graph traversal.
  class SourceProjection
    VERSION = "cnw_sources_v1"
    ISSUE_LIMIT = 50
    ENTITY_OWNERS = %w[work expression manifestation item source bibl biblList event classification].freeze
    SOURCE_FIELDS = {
      "identifiers" => "./identifier",
      "titles" => "./titleStmt/title",
      "publication" => "./pubStmt/publisher | ./pubStmt/pubPlace | ./pubStmt/date",
      "physical_description" => "./physDesc/titlePage | ./physDesc/plateNum",
      "notes" => "./notesStmt/annot",
      "links" => "./ptr | ./ref"
    }.freeze

    def initialize(input_document)
      @input = input_document
    end

    def call
      raise InputDocument::Invalid, "Source projection requires validated input" unless @input.valid?

      @issues = []
      @summary = %w[source_nodes represented_sources unsupported_sources item_nodes represented_items unsupported_items
        relation_nodes relation_tokens represented_relations unsupported_relation_nodes resolved_relations unresolved_relations]
        .to_h { |key| [key, 0] }
      @xml_ids = @input.document.xpath("//*[@xml:id]", "xml" => InputDocument::XML_NAMESPACE).to_h { |node| [node["xml:id"], node] }
      source_nodes = nodes(@input.document, "/mei/meiHead/manifestationList/manifestation")
      @represented_source_ids = source_nodes.filter_map { |node| node["xml:id"] if text(node["xml:id"]) }.to_h { |id| [id, true] }
      @summary["source_nodes"] = source_nodes.length
      descriptions = source_nodes.each_with_index.filter_map do |source, index|
        items = nodes(source, "./itemList/item")
        relations = nodes(source, "./relationList/relation")
        @summary["item_nodes"] += items.length
        @summary["relation_nodes"] += relations.length
        @summary["relation_tokens"] += relations.sum { |relation| tokens(relation).length }
        unless text(source["xml:id"])
          @summary["unsupported_sources"] += 1
          @summary["unsupported_items"] += items.length
          @summary["unsupported_relation_nodes"] += relations.length
          issue("source", source, "missing_xml_id")
          items.each { |item| issue("item", item, "unsupported_parent_source") }
          relations.each { |relation| issue("relation", relation, "unsupported_parent_source") }
          next
        end

        @summary["represented_sources"] += 1
        description(source, index + 1, items, relations)
      end
      @summary["source_state_counts"] = state_counts(descriptions)
      @summary["item_state_counts"] = state_counts(descriptions.flat_map { |source| source.fetch("held_items") })
      @summary["state"] = if source_nodes.empty?
        "absent_in_source"
      elsif @issues.any?
        "partial"
      else
        "complete"
      end
      @summary.merge!("issue_count" => @issues.length, "issues" => @issues.first(ISSUE_LIMIT), "issues_truncated" => @issues.length > ISSUE_LIMIT)
      { "version" => VERSION, "summary" => @summary, "descriptions" => descriptions }
    end

    private

    def nodes(node, path) = @input.nodes(node, path)

    def text(value)
      normalized = @input.xml_space(value)
      normalized.empty? ? nil : normalized
    end

    def metadata(node)
      { "xml_id" => node["xml:id"], "locator" => @input.locator(node), "attributes" => @input.attributes(node) }
    end

    def value(node, order)
      metadata(node).merge("element" => node.name, "text" => text(node.text), "raw_text" => node.text,
        "source_type" => node["type"], "language" => node["xml:lang"], "source_order" => order,
        "parent_metadata" => metadata(node.parent))
    end

    def values(node, path)
      nodes(node, path).each_with_index.map { |selected, index| value(selected, index + 1) }
    end

    def node_record(node, order)
      metadata(node).merge("source_order" => order, "label" => text(node["label"]), "parent_metadata" => metadata(node.parent))
    end

    def description(source, order, items, relations)
      row = node_record(source, order)
      SOURCE_FIELDS.each { |field, path| row[field] = values(source, path) }
      row["titles"].each { |title| title["title_stmt_metadata"] = title.fetch("parent_metadata") }
      row["classification_terms"] = classification_terms(source)
      descriptive_fields = %w[identifiers titles classification_terms publication physical_description notes]
      row["availability"] = descriptive_fields.to_h { |field| [field, available(row.fetch(field))] }
      row["state"] = node_state(row, descriptive_fields.flat_map { |field| row.fetch(field) }, row.fetch("links"))
      row["held_items"] = items.each_with_index.filter_map do |item, index|
        unless text(item["xml:id"])
          @summary["unsupported_items"] += 1
          issue("item", item, "missing_xml_id")
          next
        end
        @summary["represented_items"] += 1
        held_item(item, index + 1, source["xml:id"])
      end
      row["relations"] = relations.each_with_index.flat_map do |relation, index|
        tokens(relation).each_with_index.map do |token, token_index|
          relation_record(relation, index + 1, token, token_index + 1, source["xml:id"])
        end
      end
      row
    end

    def classification_terms(source)
      result = []
      nodes(source, "./classification").each do |classification|
        nodes(classification, ".//term").each do |term|
          ancestors = term.ancestors.take_while { |ancestor| ancestor != classification }
          next if ancestors.any? { |ancestor| ENTITY_OWNERS.include?(ancestor.name) }

          result << value(term, result.length + 1).merge(
            "classification_metadata" => metadata(classification),
            "term_list_metadata" => ancestors.select { |ancestor| mei_element?(ancestor, "termList") }.reverse.map { |list| metadata(list) })
        end
      end
      result
    end

    def held_item(item, order, source_id)
      row = node_record(item, order).merge("source_xml_id" => source_id,
        "identifiers" => values(item, "./identifier"),
        "physical_description" => values(item, "./physDesc/physMedium | ./physDesc/handList/hand"),
        "links" => values(item, "./ptr | ./ref"))
      row["physical_locations"] = nodes(item, "./physLoc").each_with_index.map do |location, index|
        metadata(location).merge("source_order" => index + 1, "identifiers" => values(location, "./identifier"),
          "repositories" => nodes(location, "./repository").each_with_index.map do |repository, repository_index|
            metadata(repository).merge("source_order" => repository_index + 1,
              "identifiers" => values(repository, "./identifier"), "names" => values(repository, "./corpName"),
              "links" => values(repository, "./ptr | ./ref"))
          end)
      end
      repositories = row.fetch("physical_locations").flat_map { |location| location.fetch("repositories") }
      repository_values = repositories.flat_map { |repository| repository.fetch("identifiers") + repository.fetch("names") }
      locations = row.fetch("physical_locations").flat_map { |location| location.fetch("identifiers") }
      row["availability"] = { "identifiers" => available(row.fetch("identifiers")), "repositories" => available(repository_values),
        "location_identifiers" => available(locations), "physical_description" => available(row.fetch("physical_description")) }
      row["state"] = node_state(row, row.fetch("identifiers") + repository_values + locations + row.fetch("physical_description"),
        row.fetch("links") + repositories.flat_map { |repository| repository.fetch("links") })
      row
    end

    def available(rows) = rows.any? { |row| row.fetch("text") } ? "present" : "missing"

    def node_state(row, descriptive_values, links)
      return "descriptive" if available(descriptive_values) == "present"
      return "label_or_link_stub" if row["label"] || links.any? { |link| %w[target href].any? { |key| text(link.fetch("attributes")[key]) } }

      "empty_placeholder"
    end

    def tokens(relation)
      list = @input.xml_space(relation["target"]).split(" ")
      list.empty? ? [nil] : list
    end

    def relation_record(node, order, token, token_order, source_id)
      row = metadata(node).merge("source_xml_id" => source_id, "relation_order" => order, "token_order" => token_order,
        "rel" => node["rel"], "raw_target" => node["target"], "target_token" => token,
        "parent_metadata" => metadata(node.parent), "resolution_state" => "unresolved", "resolution_reason" => nil,
        "target_source_xml_id" => nil, "expression_context" => nil)
      reason = resolve(row)
      row["resolution_reason"] = reason
      @summary["represented_relations"] += 1
      if reason
        @summary["unresolved_relations"] += 1
        issue("relation", node, reason)
      else
        @summary["resolved_relations"] += 1
      end
      row
    end

    def resolve(row)
      token = row.fetch("target_token")
      return "missing_target" unless token
      return "unsupported_relation_type" unless %w[isEmbodimentOf isReproductionOf hasReproduction].include?(row["rel"])
      return "unsupported_target_form" unless token.match?(/\A#[^#\/\?\x20\x09\x0D\x0A]+\z/)

      target = @xml_ids[token.delete_prefix("#")]
      return "missing_fragment" unless target
      if row["rel"] == "isEmbodimentOf"
        return "wrong_target_type" unless mei_element?(target, "expression")
        containing_work = target.ancestors.find { |ancestor| mei_element?(ancestor, "work") }
        return "expression_outside_supported_work" unless containing_work == @input.work

        row["resolution_state"] = "resolved_expression"
        row["expression_context"] = expression_metadata(target).merge(
          "ancestor_expressions" => target.ancestors.take_while { |ancestor| ancestor != @input.work }
            .select { |ancestor| mei_element?(ancestor, "expression") }.reverse.map { |ancestor| expression_metadata(ancestor) },
          "containing_work" => { "xml_id" => @input.work["xml:id"], "locator" => @input.locator(@input.work) })
      else
        return "wrong_target_type" unless mei_element?(target, "manifestation")
        return "unsupported_source_target" unless @represented_source_ids[target["xml:id"]]

        row["resolution_state"] = "resolved_source"
        row["target_source_xml_id"] = target["xml:id"]
      end
      nil
    end

    def mei_element?(node, name)
      node.element? && node.name == name && node.namespace&.href == @input.namespace
    end

    def expression_metadata(node)
      metadata(node).merge("label" => text(node["label"]), "titles" => values(node, "./title"))
    end

    def issue(kind, node, reason)
      row = { "kind" => kind, "locator" => @input.locator(node), "reason" => reason }
      row["xml_id"] = node["xml:id"] if text(node["xml:id"])
      @issues << row
    end

    def state_counts(rows)
      rows.each_with_object({}) { |row, counts| counts[row.fetch("state")] = counts.fetch(row.fetch("state"), 0) + 1 }
    end
  end
end
