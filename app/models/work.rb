class Work < ApplicationRecord
  belongs_to :composer
  belongs_to :catalogue_document, optional: true, inverse_of: :work
  has_many :work_titles, -> { order(:source_order, :id) }, dependent: :destroy, inverse_of: :work
  has_many :work_classification_terms, -> { order(:source_order, :id) }, dependent: :destroy,
           inverse_of: :work
  has_many :catalogue_identifiers, dependent: :destroy
  has_many :movements, -> { order(:position) }, dependent: :destroy
  has_many :instrumentations, -> { order(:name) }, dependent: :destroy
  has_many :source_references, dependent: :destroy
  has_many :performances, -> { order(:performed_on) }, dependent: :destroy
  has_many :external_references, dependent: :destroy
  has_many :import_logs, -> { order(imported_at: :desc, id: :desc) }, dependent: :nullify

  validates :title, :source_file, presence: true
  validates :source_file, uniqueness: true
  validates :catalogue_document_id, uniqueness: true, allow_nil: true
  validates :display_title_order, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  scope :search, ->(term) {
    if term.blank?
      all
    else
      pattern = "%#{sanitize_sql_like(term.to_s)}%"
      joins(:composer).where(
        <<~SQL.squish,
          EXISTS (
            SELECT 1 FROM work_titles
            WHERE work_titles.work_id = works.id AND work_titles.text ILIKE :pattern
          ) OR (works.catalogue_document_id IS NULL AND works.title ILIKE :pattern)
            OR works.catalogue_number ILIKE :pattern OR composers.name ILIKE :pattern
        SQL
        pattern: pattern
      )
    end
  }

  scope :with_catalogue_number, ->(value) {
    if value.blank?
      all
    else
      normalized_value = value.to_s.squish
      prefixed_cnw = normalized_value.match(/\ACNW\s+(.+)\z/i)

      if prefixed_cnw
        cnw_value = prefixed_cnw[1]
        matching_work_ids = CatalogueIdentifier
          .where("LOWER(BTRIM(catalogue_identifiers.identifier_type)) = ?", "cnw")
          .where(
            "LOWER(BTRIM(catalogue_identifiers.value)) IN (?)",
            [cnw_value.downcase, "cnw #{cnw_value}".downcase]
          )
          .select(:work_id)
        where(id: matching_work_ids)
      else
        where("works.catalogue_number ILIKE ?", "%#{sanitize_sql_like(value)}%")
      end
    end
  }

  scope :with_genre, ->(value) {
    if value.blank?
      all
    else
      where(
        <<~SQL.squish,
          EXISTS (
            SELECT 1 FROM work_classification_terms
            WHERE work_classification_terms.work_id = works.id
              AND work_classification_terms.text ILIKE :pattern
          ) OR (works.catalogue_document_id IS NULL AND works.genre ILIKE :pattern)
        SQL
        pattern: "%#{sanitize_sql_like(value.to_s)}%"
      )
    end
  }

  scope :with_instrumentation, ->(value) {
    if value.blank?
      all
    else
      matching_work_ids = Instrumentation.where("instrumentations.name ILIKE ?", "%#{sanitize_sql_like(value)}%").select(:work_id)
      where(id: matching_work_ids)
    end
  }

  scope :from_year, ->(year) {
    year.present? ? where("works.composition_year >= ?", year.to_i) : all
  }

  scope :to_year, ->(year) {
    year.present? ? where("works.composition_year <= ?", year.to_i) : all
  }

  def self.filtered(filters)
    search(filters[:q])
      .with_catalogue_number(filters[:catalogue_number])
      .with_instrumentation(filters[:instrumentation])
      .from_year(filters[:year_from])
      .to_year(filters[:year_to])
      .with_genre(filters[:genre])
  end

  def latest_import_attempt
    attempts_for_identity.first
  end

  def last_successful_import
    attempts = attempts_for_identity
    if attempts.loaded?
      attempts.find { |attempt| attempt.status == "success" }
    else
      attempts.where(status: "success").first
    end
  end

  private

  def attempts_for_identity
    catalogue_document ? catalogue_document.import_logs : import_logs
  end
end
