
module ActionCommand
  
  # A static description of the input and output from a given command.  Although
  # adding this adds a bunch of documentation and validation, it is not required.
  # If you don't want to specify your input and output, you can just access the hash
  # you passed into the command as @params
  class InputOutput
    # shorthand to indicate the parameter is optional.
    OPTIONAL = { optional: true }.freeze

    # Do not use this.  Instead, implment self.describe_io in your command subclass, and
    # call the method ActionCommand#self.describe_io from within it, returning its result.
    def initialize(action, desc)
      @action = action
      @desc = desc
      @input = []
      @output = []

      # universal parameters.
      # input(:help, 'Help on this command', OPTIONAL)
    end
    
    # @param dest [ActionCommand::Executable] the executable in question
    # @return true if the executable is not in a testing context.
    def should_validate(dest)
      return dest.test_context?
    end

    # Validates that the specified parameters are valid for this input description.
    # @param args [Hash] the arguments to validate
    def validate_input(dest, args)
      return true unless should_validate(dest)
      @input.each do |p|
        val = args[p[:symbol]]
      
        # if the argument has a value, no need to test whether it is optional.
        next unless !val || val == '*' || val == ''
      
        opts = p[:opts]
        unless opts[:optional]
          raise ArgumentError, "You must specify the required input #{p[:symbol]}"
        end
      end
      return true
    end
    
    # Goes through, and assigns the value for each declared parameter to an accessor
    # with the same name, validating that required parameters are not missing
    def process_input(dest, args)
      # pass down predefined attributes.
      dest.parent = args[:parent]
      dest.test   = args[:test]
      
      return unless validate_input(dest, args)

      @input.each do |param|
        sym = param[:symbol]
        if args.key? sym
          sym_assign = "#{sym}=".to_sym
          dest.send(sym_assign, args[sym])      
        end
      end
    end
    
    # Goes through, and makes sure that required output parameters exist
    def process_output(dest, result)
      return unless should_validate(dest)

      @output.each do |param|
        sym = param[:symbol]
        unless result.key?(sym)
          opts = param[:opts]
          raise ArgumentError, "Missing required value #{sym} in output" unless opts[:optional]
        end
      end
    end
    
    # convert rake task arguments to a standard hash.
    def rake_input(rake_arg)
      params = {}
      rake_arg.each do |key, val| 
        params[key] = val
      end
      return params
    end
    
    # print out the defined output of the command
    def print_output(result)
      @output.each do |param|
        sym = param[:symbol]
        puts "#{sym}: #{result[sym]}"
      end
      
    end

    # Returns the description for this command.
    attr_reader :desc

  
    def help?(args)
      first_arg_sym = @input.first[:symbol]
      first_arg_val = args[first_arg_sym]
      return first_arg_val == 'help'
    end

    # displays the help for this command
    def show_help
      puts "#{@action.name}: #{desc}"
      print_params('Input', @input)
      print_params('Output', @output)
    end
    

    # Defines input for a command
    # @param sym [Symbol] symbol identifying the parameter
    # @param desc [String] description for use by internal developers, or on a rake task with 
    #   rake your_task_name[help]
    # @param opts Optional arguments.
    def input(sym, desc, opts = {}, &_block)
      insert_io(@input, sym, desc, opts)
    end
    
    def output(sym, desc, opts = {})
      insert_io(@output, sym, desc, opts)
    end

    # @return an array with the set of parameter symbols this command accepts.
    def keys 
      @input.collect { |p| p[:symbol] }
    end
    
    private
    
    def print_params(title, vals)
      puts "  #{title}: "
      vals.each do |p|
        out = "    #{p[:symbol]}: #{p[:desc]}"
        out << ' (optional)' if p[:opts][:optional]
        puts out
      end
    end
    
    def insert_io(dest, sym, desc, opts)
      dest << { symbol: sym, desc: desc, opts: opts }
    end
    
  end
end
