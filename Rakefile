require 'rspec/core/rake_task'
require "bundler/gem_tasks"

task default: %w[spec]

RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = ['--color']
end
