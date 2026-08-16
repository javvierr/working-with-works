class Movement < ApplicationRecord
  belongs_to :work

  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
