module Parslet::Bytecode
  # Matches the string and pushes the result on the stack (looks like the
  # string, but is really the slice that was matched).
  #
  Match = Struct.new(:str) do
    def run(vm)
      error_pos = vm.source.pos
      s = vm.source.read(str.bytesize)

      vm.push(s) if s == str
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
      end
    end
  end
end