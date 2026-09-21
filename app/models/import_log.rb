class ImportLog < ApplicationRecord
  VALID_STATUSES = %w[success failure].freeze

  belongs_to :work, optional: true
  belongs_to :catalogue_document, optional: true, inverse_of: :import_logs

  validates :source_file, :status, :imported_at, presence: true
  validates :status, inclusion: { in: VALID_STATUSES }
  validate :consistent_document_ownership

  def safe_error_message
    safe_diagnostic(error_message)
  end

  def safe_warnings
    messages = Array(warnings).first(20).filter_map { |warning| safe_diagnostic(warning) }
    messages << "Additional warnings are retained in the local import log." if Array(warnings).length > 20
    messages
  end

  private

  def consistent_document_ownership
    return unless work && catalogue_document
    return if work.catalogue_document_id == catalogue_document_id

    errors.add(:catalogue_document, "must match the associated work")
  end

  def safe_diagnostic(value)
    return if value.blank?

    message = value.to_s.encode("UTF-8", invalid: :replace, undef: :replace).lines.first.to_s.strip
    return if message.blank?
    if message.match?(/<\/?[A-Za-z!?][^>]*>/)
      return "Import failed; input markup details are retained in the local import log."
    end

    message = message.gsub(%r{[a-z][a-z0-9+.-]*://[^\s<>]+}i, "[location omitted]")
    message = message.gsub(/["'](?:\/|[A-Za-z]:[\\\/])[^"'\r\n]*["']/, "[local path omitted]")
    message = message.gsub(%r{(?<![A-Za-z0-9])(?:/[A-Za-z0-9_.~%-]|[A-Za-z]:[\\/])[^\s<>"']*}, "[local path omitted]")
    message.gsub(/[[:cntrl:]]/, " ").truncate(512, omission: "…")
  end
end
