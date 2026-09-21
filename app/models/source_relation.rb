class SourceRelation < ApplicationRecord
  RESOLUTION_STATES = %w[resolved_expression resolved_source unresolved].freeze
  SOURCE_RELATIONS = %w[isReproductionOf hasReproduction].freeze

  belongs_to :catalogue_document, inverse_of: :source_relations
  belongs_to :source_description, inverse_of: :source_relations
  belongs_to :target_source_description, class_name: "SourceDescription", optional: true
  belongs_to :target_work, class_name: "Work", optional: true

  validates :locator, presence: true
  validates :relation_order, :token_order, numericality: { only_integer: true, greater_than: 0 }
  validates :token_order, uniqueness: { scope: %i[source_description_id relation_order] }
  validates :resolution_state, inclusion: { in: RESOLUTION_STATES }
  validate :consistent_document_ownership
  validate :selected_field_shapes
  validate :consistent_resolution

  private

  def consistent_document_ownership
    return unless catalogue_document

    { source_description: source_description, target_source_description: target_source_description,
      target_work: target_work }.each do |name, record|
      next unless record
      errors.add(name, "must belong to this catalogue document") unless record.catalogue_document_id == catalogue_document_id
    end
  end

  def selected_field_shapes
    %w[source_attributes parent_metadata].each do |field|
      errors.add(field, "must be an object") unless self[field].is_a?(Hash)
    end
    return if expression_context.nil? || expression_context.is_a?(Hash)

    errors.add(:expression_context, "must be an object or absent")
  end

  def consistent_resolution
    valid = case resolution_state
    when "resolved_expression"
      rel == "isEmbodimentOf" && target_work.present? && target_source_description_id.nil? &&
        resolution_reason.nil? && valid_expression_context? &&
        target_token == "##{expression_context['xml_id']}" && raw_target.present?
    when "resolved_source"
      SOURCE_RELATIONS.include?(rel) && target_source_description.present? && target_work_id.nil? &&
        expression_context.nil? && resolution_reason.nil? && raw_target.present? &&
        target_token == "##{target_source_description.xml_id}"
    when "unresolved"
      target_source_description_id.nil? && target_work_id.nil? && expression_context.nil? && resolution_reason.present?
    else
      false
    end
    errors.add(:resolution_state, "must agree with its typed target and reason") unless valid
  end

  def valid_expression_context?
    context = expression_context
    context.is_a?(Hash) && context["xml_id"].is_a?(String) && context["xml_id"].present? &&
      context["locator"].is_a?(String) && context["locator"].present? &&
      context["attributes"].is_a?(Hash) && context["titles"].is_a?(Array) &&
      context["ancestor_expressions"].is_a?(Array) && context["containing_work"].is_a?(Hash) &&
      context.dig("containing_work", "locator").is_a?(String) && context.dig("containing_work", "locator").present?
  end
end
