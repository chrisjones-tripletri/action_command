require 'action_command'

class HelloWorldCommand < ActionCommand::Executable
  attr_accessor :name, :no_output
  DESCRIPTION = 'Say hello to someone'.freeze
  
  def self.describe_io
    return ActionCommand.describe_io(self, DESCRIPTION) do |io|
      io.input(:name, 'Name of person to say hello to')
      io.input(:no_output, 'If true, intentionally produces no output', ActionCommand::OPTIONAL)
      io.output(:greeting, 'Greeting for the person')
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
  end
end
