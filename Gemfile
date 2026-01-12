source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.8"

gem "rails", "~> 7.1"

gem "bootsnap", require: false
gem "coderay", "~> 1.1"
gem "date", require: false
gem "dotenv-rails", "~> 2.8"
gem "google-cloud-firestore", "~> 2.8"
gem "google-cloud-storage", "~> 1.44"
gem "importmap-rails"
gem "jbuilder"
gem "propshaft"
gem "puma", "~> 6.0"
gem "rails-healthcheck", "~>1.4"
gem "redcarpet", "~> 3.5"
gem "sqlite3", "~> 1.4"
gem "stimulus-rails"
gem "tailwindcss-rails", "~>2.0"
gem "turbo-rails"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

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
  gem "erb_lint", "~> 0.3.1"

  # Auditing
  gem "abbrev" # Required for brakeman with Ruby 3.4+
  gem "brakeman", "~> 5.4"
  gem "bundler-audit", "~> 0.9.1"

  # Debugging
  gem "pry", "~> 0.14.2"
  gem "pry-rails", "~> 0.3.9"

  # Ruby Linter [https://github.com/rubocop/rubocop-rails]
  gem "rubocop-performance", "~> 1.15", require: false
  gem "rubocop-rails", "~> 2.17", require: false
  gem "rubocop-rspec", "~> 2.16", require: false
  gem "standard", "~> 1.20"

  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end
