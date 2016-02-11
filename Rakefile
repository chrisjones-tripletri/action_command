require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'yard'
require 'rake_command_filter'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop)
YARD::Rake::YardocTask.new(:yard)

RakeCommandFilter::RakeTask.new(:full_validation) do
  desc 'Run full validation'
  run_definition(RakeCommandFilter::RubocopCommandDefinition.new)
  run_definition(RakeCommandFilter::RSpecCommandDefinition.new)
  run_definition(RakeCommandFilter::YardCommandDefinition.new)
end

task default: :spec
