require 'action_command'

class HelloWorldCommand < ActionCommand::Executable
  attr_accessor :name, :no_output
  DESCRIPTION = 'Say hello to someone'.freeze
  
  def self.describe_io
    return ActionCommand.describe_io(self, DESCRIPTION) do |io|
      io.input(:name, 'Name of person to say hello to')
      io.input(:no_output, 'If true, intentionally produces no output', ActionCommand::OPTIONAL)
      io.output(:greeting, 'Greeting for the person')
      io.output(:context_api, 'Whether we are in an API context')
      io.output(:context_rails, 'Whether we are in a rails contact')
      io.output(:context_rake, 'Whether we are in a rails context')
      io.output(:context_test, 'Whether we are in a test context')
      io.output(:context_child, 'Whether we are in a child context')
    end
  end
  
  def initialize(args)
    @no_output = false
    super(args)
  end

  protected

  # Say hello to the specified person.
  def execute_internal(result)
    result[:greeting] = "Hello #{@name}" unless no_output
    result[:context_api] = api_context?
    result[:context_rails] = rails_context?
    result[:context_rake] = rake_context?
    result[:context_test] = test_context?       
    result[:context_child] = child_context?
    result.info { result[:greeting] }
  end
end
