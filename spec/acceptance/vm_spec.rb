require 'spec_helper'

describe 'VM operation' do
  extend Parslet
  include Parslet
  
  # Checks if the VM code parses input the same as if you did
  # parser.parse(input).
  def vm_parses(parser, input)
    result = parser.dup.parse(input)

    compiler = Parslet::Bytecode::Compiler.new
    program = compiler.compile(parser)
    
    p program

    vm = Parslet::Bytecode::VM.new
    vm.run(program, input).should == result
  end
  
  describe 'comparison parsing: ' do
    it "parses simple strings" do
      vm_parses str('foo'), 'foo'
    end
    describe 'sequences' do
      it "should parse" do
        vm_parses str('f') >> str('oo'), 'foo'
      end
    end
    describe 'alternatives' do
      it "parses left side" do
        vm_parses str('f') | str('o'), 'f'
      end
      it "parses right side" do
        vm_parses str('f') | str('o'), 'o'
      end
    end
  end
end