require 'action_command'

class FailingCommand < ActionCommand::Executable
  INFO_MSG = 'This is some info'.freeze
  ERROR_MSG = 'This command failed'.freeze
  
  def self.describe_io
    return ActionCommand.describe_io(self, 'Command with an internal failure') do |io|
    end
  end

  protected

  # Say hello to the specified person.
  def execute_internal(result)
    result.info(INFO_MSG)
    result.failed(ERROR_MSG)
  end
end
