module Api
  class BaseController < ApplicationController
    protected

    # Before Rails instrumentation reads parameters/format: malformed query
    # encodings must not escape into an HTML error page, and a known format
    # failure takes precedence. Unexpected application errors still propagate.
    def process_action(...)
      unless json_accept_allowed? && json_format_allowed?(request.path_parameters[:format])
        return render_api_error(:not_acceptable)
      end

      begin
        @query_parameters = request.query_parameters
      rescue ActionController::BadRequest
        return render_api_error(:invalid_parameters, [{ parameter: "query", message: "could not be parsed." }])
      end
      if @query_parameters.key?("format") && @query_parameters["format"] != "json"
        return render_api_error(:not_acceptable)
      end

      super
    end

    private

    def json_format_allowed?(format)
      format.nil? || format == "json"
    end

    def json_accept_allowed?
      header = request.get_header("HTTP_ACCEPT")
      return true if header.nil? || header.strip.empty?

      specificity = { "application/json" => 2, "application/*" => 1, "*/*" => 0 }
      matches = header.split(",").filter_map do |range|
        media, quality = Rack::Utils.q_values(range).first
        next unless media

        # Rack ignores malformed qualities (including negative ones), otherwise
        # turning an explicit denial into its implicit quality of one.
        explicit_quality = Rack::MediaType.params(range)["q"]
        quality = 0.0 if explicit_quality && !explicit_quality.match?(/\A[0-9]+(?:\.[0-9]+)?\z/)
        rank = specificity[Rack::MediaType.type(media).downcase]
        [rank, quality] if rank
      end
      return false if matches.empty?

      rank = matches.map(&:first).max
      quality = matches.select { |candidate, _| candidate == rank }.map(&:last).max
      quality > 0 && quality <= 1
    end

    def render_api_error(code, details = [])
      status, message = {
        invalid_parameters: [400, "Invalid request parameters."],
        not_found: [404, "Resource not found."],
        not_acceptable: [406, "Only JSON responses are supported."]
      }.fetch(code)
      render json: { error: { code: code.to_s, message: message, details: details } }, status: status
    end
  end
end
