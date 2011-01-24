
# Helper class that implements a transient cache that maps position and
# parslet object to results. 
#
class Parslet::Atoms::Context
  def initialize
    @cache = Hash.new
  end

  # Caches a parse answer for obj at source.pos. Applying the same parslet
  # at one position of input always yields the same result, unless the input
  # has changed. 
  #
  # We need the entire source here so we can ask for how many characters 
  # were consumed by a successful parse. Imitation of such a parse must 
  # advance the input pos by the same amount of bytes.
  #
  def cache(obj, source, &block)
    beg = source.pos
        
    # Not in cache yet? Return early.
    unless entry = lookup(obj, beg)
      message = catch(:error) {
        result = yield
        set obj, beg, [true, result, source.pos-beg]
        return result
      }
    
      set obj, beg, [false, message, source.pos-beg]
      throw :error, message
    end
  
    # the condition in unless has returned true, so entry is not nil.
    success, obj, advance = entry
  
    source.read(advance)
    
    throw :error, obj unless success
    return obj
  end  
  
  class Item
    attr_reader :obj, :pos
    def initialize(obj, pos)
      @obj, @pos = obj, pos
    end
    def hash
      @obj.hash - @pos
    end
    def eql?(o)
      o.obj == self.obj && o.pos == self.pos
    end
  end

private 
  def lookup(obj, pos)
    i = Item.new(obj, pos)
    @cache[i]
  end
  def set(obj, pos, val)
    i = Item.new(obj, pos)
    @cache[i] = val
  end
end