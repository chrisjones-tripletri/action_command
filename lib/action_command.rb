require "action_command/version"

# To use action command, create subclasses of ActionCommand::Executable
# and run them using the ActionCommand.execute_... variants.
module ActionCommand
  # Used as root parent of command if we are in a testing context.  
  CONTEXT_TEST  = :test
  
  # Used as root parent of command if we are in a rake task
  CONTEXT_RAKE  = :rake
  
  @@logger = nil
  @@params = {}
  

  # Set a logger to be used when creating commands.  
  # @param logger Any object that implements .error and .info
  def self.set_logger(logger)
    @@logger = logger
  end
  
  # @return a new, valid, empty result.
  def self.create_result
    return ActionCommand::Result.new(@@logger)
  end

  # Execute a command at the root level of a testing context
  # 
  # @param rspec pass in 'self' in an rspec example if you want to
  #   perform internal validations.  See {Executable#testing} to embed
  #   test code within commands.
  # @param cls [ActionCommand::Executable] the class of an Executable subclass
  # @param params [Hash] parameters used by the command.
  # @return [ActionCommand::Result]
  def self.execute_test(rspec, cls, params = {})
    params[:test] = rspec
    result = create_result
    return ActionCommand.create_and_execute(cls, params, CONTEXT_TEST, result)
  end

  # Create a global description of the inputs and outputs of a command.  Should
  # usually be called within an ActionCommand::Executable subclass in its 
  # self.describe_io method
  def self.describe_io(cmd_cls, desc)
    name = cmd_cls.name
    params = @@params[name]
    if(!params)
      params = InputOutput.new(cmd_cls, desc)
      @@params[name] = params
      yield params
    end
    return params
  end

  # Used internally, not for general purpose use.
  def self.create_and_execute(cls, params, parent, result)
    if(!params.is_a? Hash)
      raise ArgumentError.new("Expected params to be a Hash")
    end
    
    if(!cls.ancestors.include?(ActionCommand::Executable))
      raise ArgumentError.new("Expected an ActionCommand::Executable not #{cls.name}")
    end
    params[:parent] = parent
    action = cls.new(params)
    return action.execute(result)
  end
  
  # The result of one or more commands being executed.
  class Result
  
    # By default, a command is ok?
    def initialize(logger)
      @ok = true
      @values = {}
      @logger = logger
    end
    
    # Call this if your command implementation fails.  Sets
    # ok? to false on the result.
    # @param [String] message describing the failure.
    def failed(msg)
      @ok = false
      error(msg)
    end
    
    # @return [Boolean] true, up until failed has been called at least once.
    def ok?
      return @ok
    end

    # Assign some kind of a return value for use by the caller.
    def []=(key, val)
      @values[key] = val
    end
  
    # Return a value return by the command
    def [](key)
      return @values[key]
    end

    # display an informational message to the logger, if there is one.
    def info(msg)
      if(@logger)
        @logger.info(msg)
      else
        puts msg
      end
    end
    
    protected
    
    # display an error message to the logger, if there is one.
    def error(msg)
      if(@logger)
        @logger.error(msg)
      end
    end
    
  end

  # A static description of the input and output from a given command.  Although
  # adding this adds a bunch of documentation and validation, it is not required.
  # If you don't want to specify your input and output, you can just access the hash
  # you passed into the command as @params
  class InputOutput
    OPTIONAL = { optional: true }
  
    # Do not use this.  Instead, implment self.describe_io in your command subclass, and
    # call the method {ActionCommand#describe_io} from within it, returning its result.
    def initialize(action, desc)
      @action = action
      @desc = desc
      @params = []

      # universal parameters.
      input(:help, 'Help on this command', OPTIONAL)
      input(:rspec, 'Optional rspec context for performing validations via rspec_validate', OPTIONAL)
      input(:parent, 'Reference to the parent of this command, a symbol at the root', OPTIONAL)
    end

    # Validates that the specified parameters are valid for this input description.
    # @args [Hash] the arguments to validate
    def validate(args)
      @params.each do |p|
        val = args[p[:symbol]]
        if(!val || val == '*' || val == '')
          opts = p[:opts]
          if(!opts[:optional])
            raise ArgumentError.new("You must specify the required input #{p[:symbol]}")
          end
        end
      end
      return true
    end

    # Goes through, and assigns the value for each declared parameter to an accessor
    # with the same name.
    def assign_args(dest, args)
      # handle aliasing
      if(validate(args))
        @params.each do |param|
          sym = param[:symbol]
          if(args.has_key?(sym))
            sym_assign = "#{sym}=".to_sym
            dest.send(sym_assign, args[sym])      
          end
        end
      end
    end

    # Returns the description for this command.
    def description
      @desc
    end

    
    def is_help?(args)
      first_arg_sym = @params.first[:symbol]
      first_arg_val = args[first_arg_sym]
      return first_arg_val == 'help'
    end

    # displays the help for this command
    def show_help
      puts "#{@action.name}: #{@desc}"
      @params.each do |p|
        puts "    #{p[:symbol]}: #{p[:desc]}"
      end
    end

    # Defines input for a command
    # @sym [Symbol] symbol identifying the parameter
    # @desc [String] description for use by internal developers, or on a rake task with rake your_task_name[help]
    # @opts Optional arguments.
    def input(sym, desc, opts = {})
      @params.insert(0, { symbol: sym, desc: desc, opts: opts })
    end

    # @return an array with the set of parameter symbols this command accepts.
    def keys 
      @params.collect { |p| p[:symbol]}
    end
  end
  
        
  # Root class for action commands that can be executed by this library.
  # Override execute_internal to implement one, call one of the variants
  # of ActionCommand.execute_... to execute one.
  class Executable
    
    attr_accessor :parent, :test
    
    # Do not call new directly, instead use {ActionCommand#execute_...} variants.
    def initialize(args)
      self.class.describe_io.assign_args(self, args)
    end
    
    # Execute the logic of a command.  Should not usually be called
    # directly.   Command executors should call one of the ActionCommand.execute_...
    # variants. Command implementors should override
    # execute_internal.  
    # @return [ActionCommand::Result]
    def execute(result)
      execute_internal(result)
      return result
    end
    
    # Call this within a commands execution if you'd like to perform validations
    # within the testing context.  
    # @yield [context] Yields back the testing context that you passed in to {ActionCommand#execute_test}.
    def testing
      if(@test)
        yield @test
      end
    end    
    
    protected
      
    # @!visibility public
    # Override this method to implement the logic of your command
    # @param [ActionCommand::Result] a result object where you can store 
    #   the results of your logic, or indicate that the command failed.
    def execute_internal(result)
      
    end
    
  end
  
end
