class WorksController < ApplicationController
  def index
    @query = WorksQuery.new(request.query_parameters)
    @filters = @query.input_values
    unless @query.valid?
      @works = Work.none
      return render :index, status: :bad_request
    end

    @query.load(Work.preload(:composer, :instrumentations, :catalogue_identifiers, :catalogue_document))
    @works = @query.works
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
      :import_logs,
      :work_titles,
      :work_classification_terms,
      catalogue_document: [:import_logs, { source_descriptions: [:held_items, { source_relations: :target_source_description }] }]
    ).find(params[:id])
  end

  protected

  def process_action(...)
    if action_name == "index"
      begin
        request.query_parameters
      rescue ActionController::BadRequest
        @query = WorksQuery.unparseable
        @filters = @query.input_values
        @works = Work.none
        return render :index, status: :bad_request
      end
    end
    super
  end
end
