module Api
  class ErrorsController < BaseController
    def not_found
      render_api_error(:not_found)
    end

    protected

    # Unknown GET API routes have no representation to negotiate or query to
    # validate; avoid framework parameter inspection before their safe 404.
    def process_action(...)
      not_found
    end
  end
end
