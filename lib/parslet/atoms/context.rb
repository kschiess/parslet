module Parslet::Atoms
  # Helper class for detecting left-recursion in a grammar. Placed in 
  # the memo field before parsing. In case it leaks out, we make it so
  # it looks like a Base::Fail
  #
  class LeftRecursion < Struct.new(:detected)
    def error?; true end
    def message; "Unresolved left-recursion detected." end
  end

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
    # has changed or left recursion is involved.
    #
    # We need the entire source here so we can ask for how many characters 
    # were consumed by a successful parse. Imitation of such a parse must 
    # advance the input pos by the same amount of bytes.
    #
    def cache(obj, source, &block)
      beg = source.pos
      lr_info = LeftRecursion.new(false)
        
      # Not in cache yet? Return early.
      unless entry = lookup(obj, beg)
        # If given an initial state to memoize, store that before evaluating.
        # Used for left-recursion detection.
        set obj, beg, [lr_info, 0]

        result = yield

        set obj, beg, [result, source.pos-beg]

        if (lr_info.detected && !result.error?)
          result = grow(obj, source, result, beg)
        end
    
        return result
      end

      # the condition in unless has returned true, so entry is not nil.
      result, advance = entry

      # The data we're skipping here has been read before. (since it is in 
      # the cache) PLUS the actual contents are not interesting anymore since
      # we know obj matches at beg. So skip reading.
      source.pos = beg + advance

      if (result.kind_of?(LeftRecursion))
        result.detected = true
        result = Base::Fail.new("Detected left recursion.")
      end

      return result
    end

    # Attempts to 'grow' a left-recursive rule into its full form.
    #
    def grow(obj, source, result, beg)
      pos = beg
      loop do
        source.pos = beg
        ans = obj.try(source, self)
        break if (ans.error? || source.pos <= pos)
        set obj, beg, [ans, source.pos - beg]
        result = ans
        pos = source.pos
      end
      source.pos = pos
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