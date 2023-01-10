# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

if Rails.env.development?
  require "rubocop/rake_task"

  RuboCop::RakeTask.new do |task|
    task.requires << "rubocop-rails"
  end
end

Rails.application.load_tasks
