require 'parslet/atoms/visitor'

module Parslet::Bytecode
  class Compiler
    def initialize
      @buffer = []
    end
    
    def compile(atom)
      atom.accept(self)
      @buffer
    end
    def add(instruction)
      @buffer << instruction
    end
    
    def visit_str(str)
      add Match.new(str)
    end
    def visit_sequence(parslets)
      parslets.each do |atom|
        atom.accept(self)
      end
      add PackSequence.new(parslets.size)
    end

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
end