require 'action_command'

class HelloWorldCommand < ActionCommand::Executable
  attr_accessor :name
  DESCRIPTION = 'Say hello to someone'.freeze
  
  def self.describe_io
    return ActionCommand.describe_io(self, DESCRIPTION) do |io|
      io.input(:name, 'Name of person to say hello to')
    end
  end

  protected

  # Say hello to the specified person.
  def execute_internal(result)
    result[:greeting] = "Hello #{@name}"
  end
end
