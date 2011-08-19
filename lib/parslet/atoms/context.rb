module Parslet::Atoms
  # Helper class that implements a transient cache that maps position and
  # parslet object to results. This is used for memoization in the packrat
  # style. 
  #
  class Context
    
    class LRStack < Struct.new(:lrs)
      def push(lr)
        lrs.unshift(lr)
      end

      def pop
        lrs.shift
      end

      def select_top(&block)
        lrs.inject([]) do |r, lr|
          if block.call(lr)
            r << lr
          else
            return r
          end
        end
      end
    end

    attr_reader :lr_stack

    def initialize
      @cache = Hash.new { |h, k| h[k] = {} }
      @heads = {}
      @lr_stack = LRStack.new([])
    end

    def heads
      @heads
    end

    def lookup(obj, pos)
      @cache[pos][obj]
    end

    def set(obj, pos, val)
      @cache[pos][obj] = val
    end
  end
end