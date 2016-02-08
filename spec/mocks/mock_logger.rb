
# just a simple mock for a logger interface.
class MockLogger
  
  def initialize
    @info = []
    @error = []
  end
  
  # print an info message
  def info(msg)
    @info << msg
  end
  
  # get the last info message
  def last_info
    return @info.last
  end
  
  # print an error message
  def error(msg)
    @error << msg
  end
  
  # get the last error message
  def last_error
    return @error.last
  end
end
