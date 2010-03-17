
class RExpMatcher
  attr_reader :obj
  def initialize(obj)
    @obj = obj
  end
  
  def match(expression, &block)
    block.call(obj)
  end
  
  def inspect
    'r('+obj.inspect+')'
  end
end