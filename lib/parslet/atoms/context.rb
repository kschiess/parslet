module Parslet::Atoms
  # Helper class that implements a transient cache that maps position and
  # parslet object to results. This is used for memoization in the packrat
  # style. 
  #
  class Context
    def initialize
      @cache = Hash.new { |h, k| h[k] = {} }
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
        result = yield
    
        set obj, beg, [result, source.pos-beg]
        return result
      end

      # the condition in unless has returned true, so entry is not nil.
      result, advance = entry

      # The data we're skipping here has been read before. (since it is in 
      # the cache) PLUS the actual contents are not interesting anymore since
      # we know obj matches at beg. So skip reading.
      source.pos = beg + advance
      return result
    end  
  
  private 
    def lookup(obj, pos)
      @cache[pos][obj] 
    end
    def set(obj, pos, val)
      @cache[pos][obj] = val
    end
  end
end
