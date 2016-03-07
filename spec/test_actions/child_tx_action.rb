require 'action_command/executable_transaction'

class ChildTxAction < ActionCommand::ExecutableTransaction
  
  def self.describe_io
    return ActionCommand.describe_io(self, 'Creates a user') do |io|
    end
  end
  
  protected

  def execute_internal(result)
    result.info("in child transaction")
  end
  
  
end