class Parslet::Scope
  class Binding
    attr_reader :parent
    
    def initialize(parent=nil)
      @parent = parent
      @hash = Hash.new
    end
    
    def [](k)
      @hash.fetch(k)
    end
    def []=(k,v)
      @hash.store(k,v)
    end
  end
  
  def [](k)
    @current[k]
  end
  def []=(k,v)
    @current[k] = v
  end
  
  def initialize
    @current = Binding.new
  end
  
  def push
    @current = Binding.new(@current)
  end
  def pop
    @current = @current.parent
  end
end