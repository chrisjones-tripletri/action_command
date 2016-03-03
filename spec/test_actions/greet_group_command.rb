require 'action_command'

class GreetGroupCommand < ActionCommand::Executable
  attr_accessor :names
  
  DESCRIPTION = 'Say hello to a group'.freeze
  
  def self.describe_io
    return ActionCommand.describe_io(self, DESCRIPTION) do |io|
      io.input(:names, 'Array of names to create')
    end
  end
  
  protected

  # Say hello to the specified person.
  def execute_internal(result)
    @names.each_with_index do |name, i|
      ActionCommand.execute_child(self, HelloWorldCommand, result, i, name: name)
    end
  end
end
