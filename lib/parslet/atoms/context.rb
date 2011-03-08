module Parslet::Atoms
  # Helper class that implements a transient cache that maps position and
  # parslet object to results. This is used for memoization in the packrat
  # style. 
  #
  class Context
    def initialize
      @cache = Hash.new { |h, k| h[k] = {} }
      @growing = []
      reset_call_stack
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
    
    def stack(parslet, source, name)
      p [:trying, source.pos, parslet, @stack, @growing]
      pos = source.pos
      if pos != @stack_pos
        reset_call_stack(pos)
      end
      
      if @growing.include?(name)
        p [:growing_include, @growing]
        return parslet.success(nil)
      end
      
      if @stack.include?(name)
        p [:detected, @stack]
        @act_on_pop << name
        return parslet.error(source, 'Direct or indirect recursion: #{@stack.inspect}.')
      end
            
      @stack.push name

      res = yield

      if @stack_pos==pos && @stack.last == name 
        @stack.pop
        p [:pop, @stack, @act_on_pop]
        if @act_on_pop.last == name
          # This is probably the start of the recursion.
          @act_on_pop.pop
          return res if res.error?
          
          # First result
          p [:growing, res]
          results = [:sequence, res.result]
          
          @growing << name
          
          # Now try to grow this: 
          loop do
            p [:growing_inter, results]
            reset_call_stack(source.pos)
            @stack << name
            res = yield
            break if res.error?
            
            results << res.result
          end
          
          if @growing.include?(name)
            @growing = @growing.delete_if { |e| e==name }
          end

          return parslet.success(results)
        end
      end
      
      res
    end
    
    def reset_call_stack(pos=0)
      @act_on_pop = []
      @stack = []
      @stack_pos = pos
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