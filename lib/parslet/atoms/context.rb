module Parslet::Atoms
  # Helper class that implements a transient cache that maps position and
  # parslet object to results. This is used for memoization in the packrat
  # style. 
  #
  class Context
    class LR < Struct.new(:detected)
      def error?; false end
    end

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
        lr = LR.new
        memo = [lr, beg]
        set obj, beg, memo
        result = yield
        memo[0] = result
        memo[1] = source.pos - beg
        if lr.detected && !result.error?
          return grow_lr(obj, source, beg, memo, nil, &block)
        else
          return result
        end
      end

      # the condition in unless has returned true, so entry is not nil.
      result, advance = entry

      # The data we're skipping here has been read before. (since it is in 
      # the cache) PLUS the actual contents are not interesting anymore since
      # we know obj matches at beg. So skip reading.
      source.pos = beg + advance

      if result.is_a?(LR)
        result.detected = true
        # FIXME this is a quick hack, need to find out a
        return obj.error(source, 'left recursion detected')
      end

      return result
    end  
  
  private
    def grow_lr(obj, source, beg, memo, h, &block)
      loop do
        source.pos = beg
        ans = block.call
        if ans.error? || source.pos <= (memo[1] + beg)
          break
        end
        memo[0] = ans
        memo[1] = source.pos - beg
      end

      source.pos = memo[1] + beg
      memo[0]
    end

    def lookup(obj, pos)
      @cache[pos][obj]
    end
    def set(obj, pos, val)
      @cache[pos][obj] = val
    end
  end
end