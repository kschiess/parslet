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

      def mark_involved_lrs(head)
        lrs.each do |lr|
          if lr.head != head
            head.mark_involved(lr)
          else
            return
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