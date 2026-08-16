class Instrumentation < ApplicationRecord
  belongs_to :work

  validates :name, presence: true
end
