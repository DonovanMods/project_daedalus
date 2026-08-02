# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "4.0.6"

gem "rails", "~> 8.1.3", ">= 8.1.3.1"

gem "bootsnap", require: false
gem "coderay", "~> 1.1"
gem "date", require: false
gem "dotenv-rails", "~> 3.2"
gem "google-cloud-firestore", "~> 3.2"
gem "google-cloud-storage", "~> 1.62"
gem "importmap-rails"
gem "jbuilder"
gem "propshaft"
gem "puma", "~> 8.0"
gem "redcarpet", "~> 3.5"
gem "solid_cable"
gem "solid_cache"
gem "solid_queue"
gem "sqlite3", "~> 2.1"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 4.6"
gem "turbo-rails"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "factory_bot_rails"
  gem "faker"
  gem "guard", "~> 2.18"
  gem "guard-rspec", "~> 4.7"
  gem "rspec-rails"
end

group :development do
  # Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
  gem "kamal", require: false

  # Auditing
  gem "brakeman", "~> 8.0"
  gem "bundler-audit", "~> 0.9.1"

  # Debugging
  gem "pry", "~> 0.16"
  gem "pry-rails", "~> 0.3.9"

  # Ruby Linter [https://github.com/rubocop/rubocop-rails]
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false

  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end
