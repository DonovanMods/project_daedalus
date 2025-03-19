# frozen_string_literal: true

Healthcheck.configure do |config|
  config.success = 200
  config.error = 503
  config.verbose = false
  config.route = "/up"
  config.method = :get
end
