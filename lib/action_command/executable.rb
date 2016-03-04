
module ActionCommand
  # Root class for action commands that can be executed by this library.
  # Override execute_internal to implement one, call one of the variants
  # of ActionCommand.execute_... to execute one.
  class Executable
    
    attr_accessor :parent, :test
    
    # Do not call new directly, instead use ActionCommand#execute_... variants.
    def initialize(args)
      self.class.describe_io.process_input(self, args)
    end
    
    # @return [Symbol] the symbol indicating what context this 
    # action was executed in, see the ActionCommand::CONTEXT_ constants.
    def root_context
      context = parent
      context = context.parent until context.is_a? Symbol
      return context
    end
    
    # @return true if this command was executed using ActionCommand.execute_test
    def test_context?
      return root_context == ActionCommand::CONTEXT_TEST
    end
    
    # @return true if this command was executed using ActionCommand.execute_rails
    def rails_context?
      return root_context == ActionCommand::CONTEXT_RAILS
    end
    
    # @return true if this command was executed using ActionCommand.execute_rake
    def rake_context?
      return root_context == ActionCommand::CONTEXT_RAKE
    end

    # @return true if this command is a child of another command
    def child_context?
      return !parent.is_a?(Symbol)
    end
    
    # Execute the logic of a command.  Should not usually be called
    # directly.   Command executors should call one of the ActionCommand.execute_...
    # variants. Command implementors should override
    # execute_internal.  
    # @return [ActionCommand::Result]
    def execute(result)
      execute_internal(result)
      self.class.describe_io.process_output(self, result)
      return result
    end
        
    # Call this within a commands execution if you'd like to perform validations
    # within the testing context.  
    # @yield [context] Yields back the testing context that you 
    #   passed in to ActionCommand#execute_test.
    def testing
      yield @test if @test
    end    
    
    protected
      
      
    # @!visibility public
    # Override this method to implement the logic of your command
    # @param result [ActionCommand::Result] a result object where you can store 
    #   the results of your logic, or indicate that the command failed.
    def execute_internal(result)
      
    end
    
  end
end
