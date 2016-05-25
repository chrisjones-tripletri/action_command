require 'logger'
require 'action_command/version'
require 'action_command/result'
require 'action_command/input_output'
require 'action_command/executable'
require 'action_command/utils'
require 'action_command/log_parser'
require 'action_command/pretty_print_log_action'

# To use action command, create subclasses of ActionCommand::Executable
# and run them using the ActionCommand.execute_... variants.
module ActionCommand
  # 5. Begin adding documentation for how to use it.
  
  # Used as root parent of command if we are in a testing context.  
  CONTEXT_TEST = :test
  
  # Used as root parent of command if we are in a rake task
  CONTEXT_RAKE = :rake

  # Used as root parent of command if we are executing it from rails (a controller, etc)
  CONTEXT_RAILS = :rails
  
  # Used as a root element when the command is executed from an API context
  CONTEXT_API = :api
  
  # Used if a result has had no failures
  RESULT_CODE_OK = 0
  
  # Used as a generic result code for failure, if you do not provide
  # a more specific one through {ActionCommand::Result#failed_with_code}
  RESULT_CODE_FAILED = 1
  
  # log entry for the input to a commmand
  LOG_KIND_COMMAND_INPUT   = :command_input
  
  # log entry for the output from a command
  LOG_KIND_COMMAND_OUTPUT  = :command_output
  
  # info message from within a command
  LOG_KIND_INFO            = :info

  # debug message from within a command
  LOG_KIND_DEBUG           = :debug
  
  # error message from within a command
  LOG_KIND_ERROR           = :error
  
  
  # Used to create an optional parameter in describe_io
  OPTIONAL = { optional: true }.freeze

  @@logger = nil # rubocop:disable Style/ClassVars
  @@params = {}  # rubocop:disable Style/ClassVars
    
  # Set a logger to be used when creating commands.  
  # @param logger Any object that implements .error and .info
  def self.logger=(logger)
    @@logger = logger # rubocop:disable Style/ClassVars
  end
  
  # @return a new, valid, empty result.
  def self.create_result
    return ActionCommand::Result.new
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
  
  # Execute a command at the root level of a rake task context.
  # @param cls [ActionCommand::Executable] The class of an Executable subclass
  # @param args parameters used by the command.
  # @return [ActionCommand::Result]
  def self.execute_rake(cls, args)
    io = cls.describe_io
    if io.help? args
      io.show_help
      return
    end
    
    # by default, use human logging if a logger is enabled.
    args[:logger] = Logger.new(STDOUT) unless args.key?(:logger)
    args[:log_format] = :human unless args.key?(:log_format)
    
    result = create_result
    ActionCommand.create_and_execute(cls, io.rake_input(args), CONTEXT_RAKE, result)
    io.print_output(result)
    return result
  end    
  
  # Install a command as a rake task in a 
  def self.install_rake(rake, sym, cls, deps)
    rake.send(:desc, cls.describe_io.desc)
    rake.send(:task, sym, cls.describe_io.keys => deps) do |_t, args|
      ActionCommand.execute_rake(cls, args)
    end
  end    

  # Execute a command at the root level of a rails context
  # @param cls [ActionCommand::Executable] The class of an Executable subclass
  # @param params [Hash] parameters used by the command.
  # @return [ActionCommand::Result]
  def self.execute_rails(cls, params = {})
    result = create_result
    return ActionCommand.create_and_execute(cls, params, CONTEXT_RAILS, result)
  end
  
  # Execute a command at the root level of an api context
  # @param cls [ActionCommand::Executable] The class of an Executable subclass
  # @param params [Hash] parameters used by the command.
  # @return [ActionCommand::Result]
  def self.execute_api(cls, params = {})
    result = create_result
    return ActionCommand.create_and_execute(cls, params, CONTEXT_API, result)
  end
  
  # Execute a child command, placing its results under the specified subkey
  # @param parent [ActionCommand::Executable] An instance of the parent command
  # @param cls [ActionCommand::Executable] The class of an Executable subclass
  # @param result [ActionCommand::Result] The result to populate
  # @param result_key [Symbo] a key to place the results under, or nil if you want
  #   the result stored directly on the current results object.
  # @param params [Hash] parameters used by the command.
  # @return [ActionCommand::Result]
  def self.execute_child(parent, cls, result, result_key, params = {})
    result.push(result_key, cls)
    ActionCommand.create_and_execute(cls, params, parent, result)
    result.pop(result_key)
    return result
  end

  # Create a global description of the inputs and outputs of a command.  Should
  # usually be called within an ActionCommand::Executable subclass in its 
  # self.describe_io method
  def self.describe_io(cmd_cls, desc)
    name = cmd_cls.name
    params = @@params[name]
    unless params
      params = InputOutput.new(cmd_cls, desc)
      @@params[name] = params
      yield params
      params.input(:help, 'Help for this command', OPTIONAL) if params.input_count == 0
    end
    return params
  end

  # Used internally, not for general purpose use.
  def self.create_and_execute(cls, params, parent, result)
    check_params(cls, params)
    params[:parent] = parent
    logger = params[:logger]
    logger = @@logger unless logger
    log_format = :json
    log_format = params[:log_format] if params.key?(:log_format)
    result.configure_logger(logger, log_format) 
    result.root_command(cls) if parent.is_a? Symbol
    action = cls.new(params)
    
    result.log_input(params)
    action.execute(result)
    result.log_output   
    return result
  end
  
  def self.check_params(cls, params)
    raise ArgumentError, 'Expected params to be a Hash' unless params.is_a? Hash
    
    unless cls.is_a?(Class) && cls.ancestors.include?(ActionCommand::Executable)
      raise ArgumentError, 'Expected an ActionCommand::Executable as class'
    end
  end
end
