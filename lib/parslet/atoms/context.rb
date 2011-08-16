module Parslet::Atoms
  # Helper class that implements a transient cache that maps position and
  # parslet object to results. This is used for memoization in the packrat
  # style. 
  #
  class Context
    def initialize
      @cache = Hash.new { |h, k| h[k] = {} }
    end

    def lookup(obj, pos)
      @cache[pos][obj]
    end

    def set(obj, pos, val)
      @cache[pos][obj] = val
    end
  end
end