
class RExpMatcher
  attr_reader :obj
  def initialize(obj)
    @obj = obj
  end
  
  def match(expression, &block)
    
  end
  
  def inspect
    'r('+obj.inspect+')'
  end
end