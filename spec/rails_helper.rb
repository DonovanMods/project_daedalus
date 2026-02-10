# frozen_string_literal: true

require "spec_helper"
require_relative "support/factory_bot"
require_relative "support/chrome"

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"

RSpec.configure do |config|
  config.before(:each, type: :request) do
    host! "localhost"
  end

  # ActiveRecord is not used for data storage (Firestore is the backend)
  config.use_active_record = false

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
