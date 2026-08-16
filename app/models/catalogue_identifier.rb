class CatalogueIdentifier < ApplicationRecord
  belongs_to :work

  validates :value, presence: true
end
