
# Unnecessary comment for rubocop
module ActionCommand
  
  # A single entry in the action command log
  class LogMessage
    
    attr_accessor :sequence, :cmd, :kind, :msg, :key
        
    # Create a new log message
    def populate(line, msg)
      @line = line
      @sequence = msg['sequence']
      @depth = msg['depth']
      @cmd = msg['cmd']
      @kind = msg['kind']
      @msg = msg['msg']
      @key = msg['key']
    end
    
    # @return the number of parents the current command has
    def depth
      return @depth
    end
    
    # @return true if this command is the root command
    def root?
      return @depth == 0
    end
    
    # @return the line that was used to create this message.
    def line
      return @line
    end
    
    def key?(key)
      return @key == key
    end
    
    # @return true if the kinds equal (tolerant of string/symbol mismatch)
    def kind?(kind)
      kind = kind.to_s
      return @kind == kind
    end    
    
    # @return true if the cmds equal (tolerant of being passed a class)
    def command?(cmd)
      cmd = cmd.name if cmd.is_a? Class
      return @cmd == cmd
    end
    
    # @ return true if msgs equal
    def match_message?(msg)
      return @msg == msg unless msg.is_a? Hash
      msg.each do |k, v|
        k = k.to_s if k.is_a? Symbol
        return false unless @msg.key?(k)
        return false unless @msg[k] == v
      end
      return true
    end
  end
  
  # reads from a stream containing log statements, and returns
  # LogMessage entries for them.
  class LogParser
    
    # Create a new log parser for an IO subclass
    def initialize(stream, sequence = nil)
      @stream = stream
      @sequence = sequence
    end
    
    # Check if we have reached the end of the stream.
    def eof?
      return @stream.eof?
    end    
    
    # Populates a message from the next line in the
    def next(msg)
      # be tolerant of the fact that there might be other 
      # stuff in the log file.
      next_line do |input, line|
        if input.key?('sequence')
          msg.populate(line, input) unless @sequence && @sequence != input['sequence']
          return true
        end
      end
      return false
    end

    private 
    
    def next_line
      until @stream.eof?
        line = @stream.readline
        line.scan(/--\s+:\s+({.*})/) do |item|
          input = JSON.parse(item[0])
          yield input, line
        end
      end
    end
  end
  
end
