
module ActionCommand
  
  # Action that parses a log and pretty prints the log,
  # optionally filtering on a particular command sequence.
  class PrettyPrintLogAction < Executable
    attr_accessor :source, :dest, :sequence
    
    # specifies the input/output for this command
    def self.describe_io
      return ActionCommand.describe_io(self, 'Command that does some logging') do |io|
        io.input(:source, 'Stream to read')
        io.input(:sequence, 'sequence to filter on', OPTIONAL)
        io.input(:dest, 'Optional output stream, defaults to STDOUT', OPTIONAL)
      end
    end
    
    # return the destination stream, default to STDOUT
    def dest
      @dest = STDOUT unless @dest
      return @dest
    end
    
    protected
    

    # Say hello to the specified person.
    def execute_internal(_result)
      item = LogMessage.new
      parser = LogParser.new(@source, @sequence)
      sequences = {}
      # keep track of sequences, and when you complete one, then print out the 
      # entire thing at once.
      while parser.next(item)
        if item.kind?(ActionCommand::LOG_KIND_COMMAND_OUTPUT) && item.root?
          process_output(sequences, item)
        else
          process_other(sequences, item)
        end  
        item = LogMessage.new
      end
        
      # print out any incomplete sequences
      print_sequences(sequences)
    end
    
    def process_other(sequences, item)
      sequences[item.sequence] = [] unless sequences.key?(item.sequence)
      sequences[item.sequence] << item
    end    
    
    def process_output(sequences, item)
      seq = sequences[item.sequence]
      sequences.delete(item.sequence)
      seq << item
      print_sequence(seq)
    end
    
    def print_sequences(sequences)
      sequences.each do |_k, v|
        print_sequence(v)
      end
    end
    
    def print_sequence(sequence)
      sequence.each_with_index do |item, _i|
        print_sequence_item(item)
      end
    end
    
    def print_sequence_item(item)
      # indent
      if item.kind?(ActionCommand::LOG_KIND_COMMAND_INPUT)
        print_cmd_input(item)
      elsif item.kind?(ActionCommand::LOG_KIND_COMMAND_OUTPUT)
        print_cmd_output(item)
      else
        print_msg(item.depth + 1, item)
      end
    end

    def print_cmd_output(item)
      println(item.depth, 'output:')
      print_msg(item.depth + 1, item)
    end
    
    def print_cmd_input(item)
      result = item.cmd
      result << " (#{item.sequence})" if item.root?
      println(item.depth, result)
      println(item.depth + 1, 'input:')
      print_msg(item.depth + 2, item)
    end
    
    def print_msg(depth, item)
      if item.msg.is_a? String
        println(depth, item.msg)
        return
      end
      
      item.msg.each do |k, v|
        println(depth, "#{k}: #{v}")
      end
    end
    
    def println(depth, line)
      padding = ''.rjust(depth * 2)
      dest.puts("#{padding}#{line}")
    end
      
    
  end
  
end
