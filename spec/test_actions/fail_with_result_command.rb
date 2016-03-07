require 'action_command'

class FailWithResultCommand < ActionCommand::Executable
  ERROR_MSG = 'This command failed'.freeze
  CUSTOM_RESULT_CODE = 10
  
  def self.describe_io
    return ActionCommand.describe_io(self, 'Command with an internal failure') do |io|
    end
  end

  protected

  # Say hello to the specified person.
  def execute_internal(result)
    result.failed_with_code(ERROR_MSG, CUSTOM_RESULT_CODE)
  end
end
