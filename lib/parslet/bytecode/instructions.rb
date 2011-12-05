module Parslet::Bytecode
  Match = Struct.new(:str) do
    def run(vm)
      error_pos = vm.source.pos
      s = vm.source.read(str.bytesize)

      vm.push(s) if s == str
    end
  end
  PackSequence = Struct.new(:size) do
    def run(vm)
      elts = vm.pop(size)
      vm.push [:sequence, *elts]
    end
  end
end