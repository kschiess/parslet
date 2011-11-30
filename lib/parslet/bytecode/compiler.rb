require 'parslet/atoms/visitor'

module Parslet::Bytecode
  class Compiler
    def initialize
      @buffer = []
    end
    
    def compile(atom)
      atom.accept(self)
    end
    
    def visit_str(str)
      @buffer << Match.new(str)
    end

    Match = Struct.new(:str) do
      def run(vm)
        error_pos = vm.source.pos
        s = vm.source.read(str.bytesize)

        vm.push(s) if s == str
      end
    end
  end
end