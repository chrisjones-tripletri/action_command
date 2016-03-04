require 'action_command'

class NoParametersCommand < ActionCommand::Executable
  DESCRIPTION = 'Command without input'.freeze
  
  def self.describe_io
    return ActionCommand.describe_io(self, DESCRIPTION) do |io|
      io.output(:test, 'Test value')
    end
  end
  

  protected

  # Say hello to the specified person.
  def execute_internal(result)
    result[:test] = 'test'
  end
end
