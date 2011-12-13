require 'parslet/atoms/visitor'

module Parslet::Bytecode
  class Compiler
    def initialize
      @buffer = []
    end
    
    class Address
      attr_reader :address
      def initialize(address=nil)
        @address = address
      end
      def resolve(vm)
        @address = vm.buffer_pointer
      end
      def inspect
        "@#{@address}"
      end
    end
    
    def compile(atom)
      atom.accept(self)
      @buffer
    end
    def add(instruction)
      @buffer << instruction
    end
    
    def fwd_address
      Address.new
    end
    def current_address
      Address.new(buffer_pointer)    
    end
    def buffer_pointer
      @buffer.size
    end
    
    def visit_str(str)
      add Match.new(str)
    end
    def visit_sequence(parslets)
      sequence = Parslet::Atoms::Sequence.new(*parslets)
      parslets.each do |atom|
        atom.accept(self)
      end
      add PackSequence.new(
        parslets.size, 
        "Failed to match sequence (#{sequence.inspect})")
    end
    def visit_alternative(alternatives)
      adr_end = fwd_address
      
      alternatives.each_with_index do |alternative, idx|
        alternative.accept(self)
        add BranchOnSuccess.new(adr_end)
      end
      
      adr_end.resolve(self)
    end
    def visit_repetition(tag, min, max, parslet)
      add SetupRepeat.new(tag)
      start = current_address
      parslet.accept(self)
      add Repeat.new(min, max, start)
    end
    def visit_named(name, parslet)
      parslet.accept(self)
      add Box.new(name)
    end
    def visit_lookahead(positive, parslet)
      add PushPos.new
      parslet.accept(self)
      add CheckAndReset.new(positive)
    end
  end
end