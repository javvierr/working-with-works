class CatalogueIdentifier < ApplicationRecord
  belongs_to :work

  before_validation :normalize_identifier_type

  validates :identifier_type, :value, presence: true
  validates :value, uniqueness: { scope: %i[work_id identifier_type] }

  private

  def normalize_identifier_type
    self.identifier_type = identifier_type.to_s.squish.presence
  end
end
