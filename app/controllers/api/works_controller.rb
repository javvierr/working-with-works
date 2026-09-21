module Api
  class WorksController < BaseController
    include WorksHelper

    def index
      query = WorksQuery.new(@query_parameters, api: true)
      return render_api_error(:invalid_parameters, query.errors) unless query.valid?

      query.load(Work.preload(:composer, :instrumentations))
      response.set_header("X-Total-Count", query.total_count.to_s)
      response.set_header("X-Page", query.page.to_s)
      response.set_header("X-Per-Page", query.per_page.to_s)
      response.set_header("X-Total-Pages", query.total_pages.to_s)
      links = query.navigation.map do |link|
        %(<#{api_works_path}?#{link[:params].to_query}>; rel="#{link[:rel]}")
      end
      response.set_header("Link", links.join(", ")) if links.any?

      render json: query.works.map { |work| work_summary(work) }
    end

    def show
      if (@query_parameters.keys - ["format"]).any?
        return render_api_error(:invalid_parameters, [{ parameter: "query", message: "contains unsupported parameters." }])
      end
      id = valid_work_id(request.path_parameters[:id])
      return render_api_error(:not_found) unless id

      work = Work.includes(
        :composer,
        :catalogue_identifiers,
        :movements,
        :instrumentations,
        :source_references,
        :performances,
        :external_references,
        :work_titles,
        :work_classification_terms,
        :import_logs,
        catalogue_document: [:import_logs, { source_descriptions: [:held_items, { source_relations: :target_source_description }] }]
      ).find_by(id: id)

      return render_api_error(:not_found) unless work

      render json: work_detail(work)
    end

    private

    def valid_work_id(raw)
      return unless raw.is_a?(String) && raw.match?(/\A[0-9]+\z/)

      digits = raw.sub(/\A0+/, "")
      maximum = "9223372036854775807"
      return if digits.empty? || digits.length > maximum.length
      return if digits.length == maximum.length && digits > maximum

      digits.to_i
    end

    def work_summary(work)
      {
        id: work.id,
        title: work.title,
        composer: {
          id: work.composer_id,
          name: work.composer.name
        },
        catalogue_number: work.catalogue_number,
        composition_date: work.composition_date,
        composition_year: work.composition_year,
        genre: work.genre,
        instrumentation: work.instrumentations.map(&:name),
        source_file: work.source_file
      }
    end

    def work_detail(work)
      work_summary(work).merge(
        source_identifier: work.source_identifier,
        catalogue_identifiers: work.catalogue_identifiers.map { |identifier|
          {
            type: identifier.identifier_type,
            value: identifier.value
          }
        },
        movements: work.movements.map { |movement|
          {
            position: movement.position,
            title: movement.title,
            tempo_marking: movement.tempo_marking,
            duration: movement.duration
          }
        },
        sources: work.source_references.map { |source|
          {
            label: source.label,
            type: source.source_type,
            repository: source.repository,
            description: source.description
          }
        },
        performances: work.performances.map { |performance|
          {
            performed_on: performance.performed_on,
            location: performance.location,
            performers: performance.performers,
            note: performance.note
          }
        },
        external_references: work.external_references.map { |reference|
          {
            label: reference.label,
            url: reference.url
          }
        }
      ).merge(work_projection(work))
    end
  end
end
