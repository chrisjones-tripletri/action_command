
class MockActiveRecord
  
  attr_accessor :id
  
  def self.find(id)
    return MockActiveRecord.new(id)
  end
  
  def initialize(id)
    @id = id
  end
  
  
end
