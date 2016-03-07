module ActionCommand
  # Root class for action commands that can be executed by this library.
  # Override execute_internal to implement one, call one of the variants
  # of ActionCommand.execute_... to execute one.
  class ExecutableTransaction < Executable
    
    # starts a transaction only if we are not already within one.
    def execute(result)
      if ActiveRecord::Base.connection.open_transactions >= 1
        super(result)
      else
        result.info('start_transaction')
        ActiveRecord::Base.transaction do
          super(result)
          if result.ok?
            result.info('end_transaction')
          else
            result.info('rollback_transaction')
            raise ActiveRecord::Rollback, 'rollback transaction'
          end
        end
      end
    end
    
  end
  
end
