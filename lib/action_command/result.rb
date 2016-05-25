
module ActionCommand
  
  
  # The result of one or more commands being executed.
  class Result # rubocop:disable Metrics/ClassLength
    # By default, a command is ok?
    def initialize
      @result_code = RESULT_CODE_OK
      @last_error  = nil
      @values = [{}]
      @logger = nil
    end
    
    # set the logger for this result
    def configure_logger(logger, format)
      return unless logger
      @sequence = SecureRandom.hex 
      @stack = [] 
      @logger = logger
      @log_format = format
    end

    # @return true if logging is enabled.
    def logging?
      return !@logger.nil?
    end

    # display an debugging message to the logger, if there is one.
    # @yield return a message or hash
    def debug(msg = nil)
      if @logger
        msg = build_log(msg || yield, ActionCommand::LOG_KIND_DEBUG)
        @logger.info(format_log(msg))
      end
    end
  
    # display an informational message to the logger, if there is one.
    # @yield return a message or hash
    def info(msg = nil)
      if @logger
        msg = build_log(msg || yield, ActionCommand::LOG_KIND_INFO)
        @logger.info(format_log(msg))
      end
    end
  
    # display an error message to the logger, if there is one.
    def error(msg)
      if @logger
        msg = build_log(msg, ActionCommand::LOG_KIND_ERROR)
        @logger.error(format_log(msg))
      end
    end
  
    # Call this if your command implementation fails.  Sets
    # ok? to false on the result.
    # @param msg [String] message describing the failure.
    def failed(msg)
      @result_code = RESULT_CODE_FAILED
      @last_error  = msg
      error(msg)
    end
    
    # Call this if your command implementation fails.  Sets
    # ok? to false on the result.
    # @param msg [String] message describing the failure.
    # @param result_code [Integer]
    def failed_with_code(msg, result_code)
      @result_code = result_code
      @last_error = msg
      error(msg)
    end
  
    # @return [Boolean] true, up until failed has been called at least once.
    def ok?
      return @result_code == RESULT_CODE_OK
    end
    
    # @return [Integer] the current result code
    attr_reader :result_code
    
    # @return [String] the last string error message
    attr_reader :last_error
    
    # adds results under the subkey until pop is called
    def push(key, cmd)
      return unless key
      old_cur = current
      if old_cur.key?(key)
        @values << old_cur[key]
      else
        @values << {}
        old_cur[key] = @values.last
      end
      @stack << { key: key, cmd: cmd } if @logger
    end
    
    # removes the current set of results from the stack.
    def pop(key)
      return unless key
      @values.pop
      @stack.pop if @logger
    end
    
    # returns the current hash of values we are operating on.
    def current
      return @values.last
    end

    # Assign some kind of a return value for use by the caller.
    def []=(key, val)
      current[key] = val
    end
    
    # return the unique sequence id for the commands under this result
    def sequence
      return @sequence
    end
    
    # determine if a key exists in the result.
    def key?(key)
      return current.key?(key)
    end
    
    # Return a value return by the command
    def [](key)
      return current[key]
    end
    
    # Used internally to log the input parameters to a command
    def log_input(params)
      return unless @logger
      output = params.reject { |k, _v| internal_key?(k) }
      log_info_hash(output, ActionCommand::LOG_KIND_COMMAND_INPUT)
    end

    # Used internally to log the output parameters for a command.
    def log_output
      return unless @logger
      # only log the first level parameters, subcommands will log
      # their own output.
      output = current.reject { |k, v| v.is_a?(Hash) || internal_key?(k) }
      log_info_hash(output, ActionCommand::LOG_KIND_COMMAND_OUTPUT) 
    end
    
    # Used internally to establish the class of the root command
    def root_command(cls)
      @stack << { key: nil, cmd: cls }  if @logger
    end
    

    private 
    
    def internal_key?(k)
      return k == :logger || k == :test || k == :parent
    end

    def log_info_hash(params, kind)
      return unless @logger
      msg = build_log(params, kind)
      @logger.info(format_log(msg))
    end
    
    def build_log(msg, kind)
      cur = @stack.last
      out = { 
        sequence: @sequence,
        cmd: cur[:cmd].name,
        depth: @stack.length - 1
      }
      out[:key] = cur[:key] if cur[:key]
      out[:kind] = kind
      out[:msg] = msg if msg
      return out
    end
    
    def format_log(msg)
      return JSON.generate(msg) unless @log_format == :human

      depth = msg[:depth]
      kind = msg[:kind]
      message = msg[:msg]
      cmd = msg[:cmd]
      return format_human_log(depth, cmd, kind, message)
    end
    
    def format_human_log(depth, cmd, kind, msg)
      base_depth = 2 * depth
      extra_depth = base_depth + 2
      if kind == ActionCommand::LOG_KIND_COMMAND_INPUT
        cmd = "#{cmd}: #{msg}"
        return cmd.rjust(cmd.length + base_depth)
      elsif kind == ActionCommand::LOG_KIND_COMMAND_OUTPUT
        out = "output: #{msg}"
        return out.rjust(out.length + extra_depth)
      elsif msg
        return msg.rjust(msg.to_s.length + extra_depth)
      end
    end
  end
end
