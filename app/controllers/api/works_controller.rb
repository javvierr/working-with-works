module Api
  class WorksController < ApplicationController
    def index
      works = Work.includes(:composer, :instrumentations)
                  .filtered(filter_params)
                  .order(:title)

      render json: works.map { |work| work_summary(work) }
    end

    def show
      work = Work.includes(
        :composer,
        :catalogue_identifiers,
        :movements,
        :instrumentations,
        :source_references,
        :performances,
        :external_references
      ).find(params[:id])

      render json: work_detail(work)
    end

    private

    def filter_params
      params.permit(:q, :catalogue_number, :instrumentation, :year_from, :year_to, :genre)
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
      )
    end
  end
end
