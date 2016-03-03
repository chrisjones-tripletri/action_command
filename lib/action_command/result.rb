
module ActionCommand
  # The result of one or more commands being executed.
  class Result
    # By default, a command is ok?
    def initialize(logger)
      @ok = true
      @values = [{}]
      @logger = logger
    end
  
    # Call this if your command implementation fails.  Sets
    # ok? to false on the result.
    # @param msg [String] message describing the failure.
    def failed(msg)
      @ok = false
      error(msg)
    end
  
    # @return [Boolean] true, up until failed has been called at least once.
    def ok?
      return @ok
    end
    
    # adds results under the subkey until pop is called
    def push(key)
      return unless key
      old_cur = current
      if old_cur.key?(key)
        @values << old_cur[key]
      else
        @values << {}
        old_cur[key] = @values.last
      end
    end
    
    # removes the current set of results from the stack.
    def pop(key)
      return unless key
      @values.pop
    end
    
    # returns the current hash of values we are operating on.
    def current
      return @values.last
    end

    # Assign some kind of a return value for use by the caller.
    def []=(key, val)
      current[key] = val
    end
    
    # determine if a key exists in the result.
    def key?(key)
      return current.key?(key)
    end
    
    # Return a value return by the command
    def [](key)
      return current[key]
    end

    # display an informational message to the logger, if there is one.
    def info(msg)
      @logger.info(msg) if @logger
    end
  
    protected
  
    # display an error message to the logger, if there is one.
    def error(msg)
      @logger.error(msg) if @logger
    end
  
  end
end
