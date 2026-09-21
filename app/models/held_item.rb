class HeldItem < ApplicationRecord
  STATES = %w[descriptive label_or_link_stub empty_placeholder].freeze
  ARRAY_FIELDS = %w[identifiers physical_locations physical_description links].freeze
  OBJECT_FIELDS = %w[source_attributes parent_metadata availability].freeze

  belongs_to :catalogue_document, inverse_of: :held_items
  belongs_to :source_description, inverse_of: :held_items

  validates :xml_id, :locator, presence: true
  validates :xml_id, uniqueness: { scope: :catalogue_document_id }
  validates :source_order, numericality: { only_integer: true, greater_than: 0 },
                           uniqueness: { scope: :source_description_id }
  validates :state, inclusion: { in: STATES }
  validate :consistent_document_ownership
  validate :selected_field_shapes

  private

  def consistent_document_ownership
    return unless source_description && catalogue_document
    return if source_description.catalogue_document_id == catalogue_document_id

    errors.add(:catalogue_document, "must match the parent source description")
  end

  def selected_field_shapes
    ARRAY_FIELDS.each { |field| errors.add(field, "must be an array") unless self[field].is_a?(Array) }
    OBJECT_FIELDS.each { |field| errors.add(field, "must be an object") unless self[field].is_a?(Hash) }
  end
end
