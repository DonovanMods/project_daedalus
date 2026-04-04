# frozen_string_literal: true

# Rack middleware that catches malformed request URIs (e.g., bad percent-encoding,
# invalid UTF-8 byte sequences) and returns a 400 Bad Request instead of letting
# them propagate as 500 errors.
class CatchBadRequestUri
  def initialize(app)
    @app = app
  end

  def call(env)
    validate_uri(env["PATH_INFO"].to_s)
    validate_uri(env["QUERY_STRING"].to_s) if env["QUERY_STRING"].present?
    validate_uri(env["REQUEST_URI"].to_s) if env["REQUEST_URI"].present?

    @app.call(env)
  rescue URI::InvalidURIError, Encoding::CompatibilityError, ArgumentError
    [400, {"content-type" => "text/plain"}, ["Bad Request"]]
  end

  private

  def validate_uri(value)
    decoded = URI.decode_www_form_component(value)
    raise ArgumentError, "Invalid encoding in URI" unless decoded.valid_encoding?
  end
end
