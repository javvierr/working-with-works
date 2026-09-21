# frozen_string_literal: true
# Synthetic fixture loading only. Expected query results remain in the frozen
# prospective files and are never computed through an application query helper.
require "json"
require "digest"

module F3SyntheticFixture
  module_function

  def load!(truth)
    composers = truth.fetch("rows").map { |row| row.fetch("composer") }.uniq.to_h do |name|
      [name, Composer.create!(name: name)]
    end
    truth.fetch("rows").sort_by { |row| row.fetch("insertion_rank") }.each do |row|
      document = if row.fetch("projected_demo")
        CatalogueDocument.create!(
          input_profile: "demo", catalogue: "F3 synthetic", record_key: row.fetch("external_key"),
          committed_sha256: Digest::SHA256.hexdigest(row.fetch("external_key")),
          root_xml_id: row.fetch("external_key"), origin_relative_name: row.fetch("source_file")
        )
      end
      work = Work.create!(
        composer: composers.fetch(row.fetch("composer")), catalogue_document: document,
        title: row.fetch("title"), catalogue_number: row["catalogue_number"],
        composition_year: row["composition_year"], composition_date: row["composition_date"],
        genre: row["genre"], source_file: row.fetch("source_file"), source_identifier: row.fetch("source_identifier"),
        display_title_order: document ? 1 : nil, display_title_reason: document ? "main" : nil
      )
      row.fetch("retained_titles").each_with_index do |value, index|
        work.work_titles.create!(text: value, raw_text: value, source_order: index + 1,
          locator: "/synthetic/f3/title[#{index + 1}]", source_type: index.zero? && document ? "main" : "alternative")
      end
      row.fetch("retained_classifications").each_with_index do |value, index|
        work.work_classification_terms.create!(text: value, raw_text: value, source_order: index + 1,
          locator: "/synthetic/f3/classification[#{index + 1}]")
      end
      row.fetch("catalogue_identifiers").each do |value|
        work.catalogue_identifiers.create!(identifier_type: value.fetch("type"), value: value.fetch("value"))
      end
      row.fetch("instrumentation").each { |value| work.instrumentations.create!(name: value) }
    end
  end
end
