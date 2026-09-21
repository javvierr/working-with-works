# Shared, bounded decisions for the read-only HTML and JSON work indexes.
class WorksQuery
  TEXT_FIELDS = %i[q catalogue_number instrumentation genre].freeze
  YEAR_FIELDS = %i[year_from year_to].freeze
  FIELDS = (%i[page per_page] + TEXT_FIELDS + YEAR_FIELDS).freeze

  attr_reader :errors, :filters, :input_values, :page, :per_page,
              :total_count, :total_pages, :works

  def initialize(raw_query, api: false)
    @errors = []
    @filters = {}
    @input_values = {}
    @page = 1
    @per_page = 20
    @total_count = @total_pages = 0
    FIELDS.each do |field|
      next unless raw_query.key?(field.to_s)

      value = raw_query[field.to_s]
      unless value.is_a?(String)
        add_error(field, "must be a scalar string.")
        next
      end

      value = value.strip
      @input_values[field] = value
      case field
      when :page, :per_page
        maximum = field == :page ? 1_000_000 : 100
        number = decimal(value, maximum)
        if number
          field == :page ? @page = number : @per_page = number
        else
          add_error(field, "must be a positive decimal integer between 1 and #{maximum}.")
        end
      when *TEXT_FIELDS
        if value.length > 200
          add_error(field, "must be at most 200 characters.")
        elsif !value.empty?
          @filters[field] = value
        end
      when *YEAR_FIELDS
        next if value.empty?

        number = decimal(value, 9999)
        if number
          @filters[field] = number
        else
          add_error(field, "must be a decimal integer between 1 and 9999.")
        end
      end
    end
    if filters[:year_from] && filters[:year_to] && filters[:year_from] > filters[:year_to]
      add_error(:year_to, "must be greater than or equal to year_from.")
    end
    if api && (raw_query.keys - FIELDS.map(&:to_s) - ["format"]).any?
      add_error(:query, "contains unsupported parameters.")
    end
  end

  def valid?
    errors.empty?
  end

  def load(relation)
    raise ArgumentError, "Cannot load an invalid work query" unless valid?

    filtered = relation.filtered(filters)
    @total_count = filtered.count
    @total_pages = (total_count.to_f / per_page).ceil
    @works = filtered.reorder("works.title ASC", "works.id ASC")
                     .offset((page - 1) * per_page).limit(per_page)
    self
  end

  def navigation
    return [] if total_pages.zero?

    destinations = if page > total_pages
      { first: 1, last: total_pages }
    else
      {}.tap do |links|
        links.merge!(first: 1, prev: page - 1) if page > 1
        links.merge!(next: page + 1, last: total_pages) if page < total_pages
      end
    end
    destinations.map do |rel, target_page|
      { rel: rel, params: filters.merge(page: target_page, per_page: per_page) }
    end
  end

  def self.unparseable
    new({}).tap { |query| query.errors << { parameter: "query", message: "could not be parsed." } }
  end

  private

  def add_error(field, message)
    errors << { parameter: field.to_s, message: message }
  end

  def decimal(value, maximum)
    return unless value.match?(/\A[0-9]+\z/)

    digits = value.sub(/\A0+/, "")
    return if digits.empty? || digits.length > maximum.to_s.length

    number = digits.to_i
    number if number <= maximum
  end
end
