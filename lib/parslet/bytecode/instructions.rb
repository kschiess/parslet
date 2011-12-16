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
      
      unless vm.success?
        occurrences, accumulator = vm.pop(2)

        # We've encountered an error. Are we still below the minimum number of
        # matches?
        if occurrences < min
          vm.set_error
            source.error("dadada", start_position)
          return
        end
        
        # assert: occurrences >= min
        
        # We've matched the minimum number required, so this is a success: 
        vm.clear_error
        vm.push accumulator
        return
      end

      # assert: vm.success?
      
      result = vm.pop
      occurrences, accumulator = vm.pop(2)

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
  PackSequence = Struct.new(:size, :error) do
    def run(vm)
      source = vm.source
      
      elts = vm.pop(size)
      
      if vm.success?
        vm.push [:sequence, *elts]
      else
        vm.set_error(
          source.error(error))
      end
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

  # Boxes a value inside a name tag.
  #
  # Consumes: parslet result
  # Pushes: boxed result
  #
  Box = Struct.new(:name) do
    def run(vm)
      if vm.success?
        result = vm.pop
        vm.push(name => result)
      end
    end
  end

  # Pushes the current source pos to the stack.
  #
  # Consumes: Nothing
  # Pushes: the current source.pos
  #
  PushPos = Class.new do
    def run(vm)
      source = vm.source 
      vm.push source.pos
    end
  end

  # Assumes that the stack contains the result of a parslet and above it 
  # the source position from before parsing that parslet (as per PushPos).
  # Will remove both and leave the vm in a state that indicates the result 
  # of a lookahead, stack will be nil (no capture) and the error flag will 
  # be set. 
  #
  # Consumes: VM state, source.pos
  # Pushes: VM.state
  # Effects: resets source.pos
  #
  CheckAndReset = Struct.new(:positive) do
    def run(vm)
      source = vm.source
      
      vm.pop if vm.success?
      
      start_pos = vm.pop
      source.pos = start_pos
      
      if positive && vm.success? || !positive && !vm.success?
        vm.clear_error
        vm.push nil
      else
        vm.set_error source.error('lookahead:error missing', start_pos)
      end
    end
  end
  
  # Compiles the block or 'calls' the subroutine that was compiled earlier.
  #
  CompileOrJump = Struct.new(:compiler, :block) do
    def run(vm)
      if @compiled_address
        vm.call(@compiled_address)
      else
        # TODO raise not implemented if the block returns nil (see Entity)
        atom = block.call
        @compiled_address = compiler.current_address
        atom.accept(compiler)
        compiler.add Return.new
        
        vm.call(@compiled_address)
      end
    end
  end
  Return = Class.new do
    def run(vm)
      vm.call_ret
    end
  end
  Stop = Class.new do
    def run(vm)
      vm.stop
    end
  end
end