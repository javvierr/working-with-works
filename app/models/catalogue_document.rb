class CatalogueDocument < ApplicationRecord
  INPUT_PROFILES = %w[official_cnw_v401 demo].freeze

  # Remove edges first: local reproduction cycles and expression targets must
  # not prevent the subsequent deletion of their source rows or Work.
  has_many :source_relations, dependent: :delete_all, inverse_of: :catalogue_document
  has_many :source_descriptions, -> { order(:source_order, :id) }, dependent: :destroy,
           inverse_of: :catalogue_document
  has_many :held_items, inverse_of: :catalogue_document
  has_one :work, dependent: :destroy, inverse_of: :catalogue_document
  has_many :import_logs, -> { order(imported_at: :desc, id: :desc) }, dependent: :nullify,
           inverse_of: :catalogue_document

  validates :input_profile, :catalogue, :record_key, :committed_sha256, presence: true
  validates :input_profile, inclusion: { in: INPUT_PROFILES }
  validates :record_key, uniqueness: { scope: %i[input_profile catalogue] }
  validates :committed_sha256, format: { with: /\A[0-9a-f]{64}\z/ }
  validate :source_projection_marker_and_summary

  private

  def source_projection_marker_and_summary
    return if source_projection_version.nil? && source_projection_summary.nil?

    errors.add(:source_projection_version, "must identify the stored projection") if source_projection_version.blank?
    unless source_projection_summary.is_a?(Hash) &&
           %w[absent_in_source complete partial].include?(source_projection_summary["state"])
      errors.add(:source_projection_summary, "must be a projected state object")
    end
  end
end
