# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require "rubocop/rake_task"
require_relative "config/application"

RuboCop::RakeTask.new do |task|
  task.requires << "rubocop-rails"
end

Rails.application.load_tasks
