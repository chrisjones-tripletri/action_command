require 'action_command'

class ParentWithLoggingCommand < ActionCommand::Executable
  TEST_INFO_STRING = 'my info'.freeze
  TEST_DEBUG_STRING = 'my debug'.freeze
  TEST_OUTPUT = 'SOME_TEST_OUTPUT'.freeze
  
  attr_accessor :test_in
  
  def self.describe_io
    return ActionCommand.describe_io(self, 'Command that does some logging') do |io|
      io.input(:test_in, 'Some test input')
      io.output(:test_out, 'Some test output')
    end
  end

  protected

  # Say hello to the specified person.
  def execute_internal(result)
    result.info(TEST_INFO_STRING)  
    result.debug(TEST_DEBUG_STRING)
    ActionCommand.execute_child(self, HelloWorldCommand, result, 1, name: 'Chris')      
    result[:test_out] = TEST_OUTPUT
  end
end
