class SourceDescription < ApplicationRecord
  STATES = %w[descriptive label_or_link_stub empty_placeholder].freeze
  ARRAY_FIELDS = %w[identifiers titles classification_terms publication physical_description notes links].freeze
  OBJECT_FIELDS = %w[source_attributes parent_metadata availability].freeze

  belongs_to :catalogue_document, inverse_of: :source_descriptions
  has_many :source_relations, -> { order(:relation_order, :token_order, :id) },
           dependent: :destroy, inverse_of: :source_description
  has_many :held_items, -> { order(:source_order, :id) }, dependent: :destroy,
           inverse_of: :source_description

  validates :xml_id, :locator, presence: true
  validates :xml_id, uniqueness: { scope: :catalogue_document_id }
  validates :source_order, numericality: { only_integer: true, greater_than: 0 },
                           uniqueness: { scope: :catalogue_document_id }
  validates :state, inclusion: { in: STATES }
  validate :selected_field_shapes

  private

  def selected_field_shapes
    ARRAY_FIELDS.each { |field| errors.add(field, "must be an array") unless self[field].is_a?(Array) }
    OBJECT_FIELDS.each { |field| errors.add(field, "must be an object") unless self[field].is_a?(Hash) }
  end
end
