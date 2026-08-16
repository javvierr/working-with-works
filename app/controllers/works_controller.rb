class WorksController < ApplicationController
  def index
    @filters = filter_params
    @works = Work.includes(:composer, :instrumentations)
                 .filtered(@filters)
                 .order(:title)
  end

  def show
    @work = Work.includes(
      :composer,
      :catalogue_identifiers,
      :movements,
      :instrumentations,
      :source_references,
      :performances,
      :external_references,
      :import_logs
    ).find(params[:id])
  end

  private

  def filter_params
    params.permit(:q, :catalogue_number, :instrumentation, :year_from, :year_to, :genre)
  end
end
