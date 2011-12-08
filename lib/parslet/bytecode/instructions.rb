module Parslet::Bytecode
  # Matches the string and pushes the result on the stack (looks like the
  # string, but is really the slice that was matched).
  #
  Match = Struct.new(:str) do
    def initialize(str)
      super
      @mismatch_error_prefix = "Expected #{str.inspect}, but got "
    end
    
    def run(vm)
      source = vm.source
      error_pos = source.pos
      s = source.read(str.bytesize)

      if !s || s.size != str.size
        source.pos = error_pos
        vm.set_error source.error("Premature end of input")
      else
        if s == str
          vm.push(s)
        else
          source.pos = error_pos
          vm.set_error source.error([@mismatch_error_prefix, s])
        end
      end
    end
  end
  
  SetupRepeat = Struct.new(:tag) do
    def run(vm)
      vm.push 0       # occurrences
      vm.push [tag]   # will collect results
    end
  end
  
  # Repeat matching with a minimum of min and a maximum of max times. 
  # 
  Repeat = Struct.new(:min, :max, :adr) do
    def run(vm)
      source = vm.source
      start_position = source.pos
      
      result = vm.pop(1)
      occurrences, accumulator = vm.pop(2)

      unless vm.success?
        # We've encountered an error. Are we still below the minimum number of
        # matches?
        if occurrences < min
          vm.set_error
            source.error("dadada", start_position)
          return
        end
        
        # assert: occurrences >= min
        vm.clear_error
        vm.push accumulator
      end

      # assert: vm.success?
      
      accumulator << result
      occurrences += 1

      # All went well but we have reached our maximum?
      if max && occurrences >= max
        # We're done! Push the result.
        vm.push accumulator
        return
      end

      # No maximum was set or it was not reached. Continue matching.
      vm.push occurrences
      vm.push accumulator
      vm.jump adr
    end
  end
  
  
  # Packs size stack elements into an array that is prefixed with the
  # :sequence tag. This will later be converted by CanFlatten.flatten
  #
  PackSequence = Struct.new(:size) do
    def run(vm)
      elts = vm.pop(size)
      vm.push [:sequence, *elts]
    end
  end
  
  # If the vm.success? is true, branches to the given address. 
  #
  BranchOnSuccess = Struct.new(:adr) do
    def run(vm)
      if vm.success?
        vm.jump(adr)
      else
        # Otherwise, clear the error and try the alternative that comes
        # right here in the byte code.
        vm.clear_error
      end
    end
  end
end