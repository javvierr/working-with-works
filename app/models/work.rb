class Work < ApplicationRecord
  belongs_to :composer
  has_many :catalogue_identifiers, dependent: :destroy
  has_many :movements, -> { order(:position) }, dependent: :destroy
  has_many :instrumentations, -> { order(:name) }, dependent: :destroy
  has_many :source_references, dependent: :destroy
  has_many :performances, -> { order(:performed_on) }, dependent: :destroy
  has_many :external_references, dependent: :destroy
  has_many :import_logs, dependent: :nullify

  validates :title, :source_file, presence: true
  validates :source_file, uniqueness: true

  scope :search, ->(term) {
    if term.blank?
      all
    else
      pattern = "%#{sanitize_sql_like(term)}%"
      joins(:composer).where(
        "works.title ILIKE :pattern OR works.catalogue_number ILIKE :pattern OR composers.name ILIKE :pattern",
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
    value.blank? ? all : where("works.genre ILIKE ?", "%#{sanitize_sql_like(value)}%")
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
end
