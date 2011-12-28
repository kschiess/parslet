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
      def to_s
        "@#{address}"
      end
    end
    
    def compile(atom)
      atom.accept(self)
      add Stop.new
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
    def visit_re(match)
      add Re.new(match, 1)
    end
    def visit_sequence(parslets)
      sequence = Parslet::Atoms::Sequence.new(*parslets)
      error_msg = "Failed to match sequence (#{sequence.inspect})"
      
      end_adr = fwd_address
      parslets.each_with_index do |atom, idx|
        atom.accept(self)
        add CheckSequence.new(idx, end_adr, error_msg)
      end
            
      add PackSequence.new(parslets.size)

      end_adr.resolve(self)
    end
    def visit_alternative(alternatives)
      adr_end = fwd_address
      
      add EnterFrame.new
      add PushPos.new
      alternatives.each_with_index do |alternative, idx|
        alternative.accept(self)
        add BranchOnSuccess.new(adr_end, idx)
      end
      add Fail.new(["Expected one of ", alternatives.inspect], alternatives.size)
      
      adr_end.resolve(self)
    end
    def visit_repetition(tag, min, max, parslet)
      add SetupRepeat.new(tag)
      start = current_address
      parslet.accept(self)
      add Repeat.new(min, max, start, parslet)
    end
    def visit_named(name, parslet)
      parslet.accept(self)
      add Box.new(name)
    end
    def visit_lookahead(positive, parslet)
      add PushPos.new
      parslet.accept(self)
      add CheckAndReset.new(positive, parslet)
    end
    def visit_entity(name, block)
      add CompileOrJump.new(self, block)
    end
    def visit_parser(root)
      root.accept(self)
    end
  end
end