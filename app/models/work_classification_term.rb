class WorkClassificationTerm < ApplicationRecord
  belongs_to :work, inverse_of: :work_classification_terms

  validates :text, :locator, presence: true
  validates :source_order, numericality: { only_integer: true, greater_than: 0 },
                           uniqueness: { scope: :work_id }
  validates :xml_id, uniqueness: { scope: :work_id }, allow_nil: true
end
