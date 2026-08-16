class ImportLog < ApplicationRecord
  VALID_STATUSES = %w[success failure].freeze

  belongs_to :work, optional: true

  validates :source_file, :status, :imported_at, presence: true
  validates :status, inclusion: { in: VALID_STATUSES }
end
