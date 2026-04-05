# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ProjectDaedalus
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Catch malformed URIs before they reach Rails routing
    require_relative "../app/middleware/catch_bad_request_uri"
    config.middleware.insert_before 0, CatchBadRequestUri

    # Don't generate system test files.
    config.generators.system_tests = nil

    # i18n configuration
    config.i18n.default_locale = :en
    # Add validated locale symbols here as translations are reviewed (e.g. %i[en es fr de])
    config.i18n.available_locales = %i[en]
    config.i18n.fallbacks = true
  end
end
