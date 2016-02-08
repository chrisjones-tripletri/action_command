require 'action_command'

class InternalTestCommand < ActionCommand::Executable
  INFO_MSG = 'This is some info'.freeze
  ERROR_MSG = 'This command failed'.freeze
  
  def self.describe_io
    return ActionCommand.describe_io(self, 'Command some internal test cases') do |io|
    end
  end

  protected

  # Say hello to the specified person.
  def execute_internal(_result)
    
    # use the testing keyword
    testing do |r|
      r.expect(1).to r.eq(2)
    end
  end
end
