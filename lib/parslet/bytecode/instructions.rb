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