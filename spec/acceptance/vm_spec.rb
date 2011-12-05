require 'spec_helper'

describe 'VM operation' do
  extend Parslet
  
  [
    # string atoms
    [str('foo'), 'foo'], 
    
    # sequences
    [str('f') >> str('oo'), 'foo'], 
    
    # alternatives
    [str('f') | str('o'), 'f'], 
    [str('f') | str('o'), 'o']
  ].each do |parser, input|
    describe "parsing #{input.inspect} with parser: #{parser.inspect}" do
      it "should behave the same as old mode" do
        result = parser.dup.parse(input)

        compiler = Parslet::Bytecode::Compiler.new
        program = compiler.compile(parser)
        
        p program

        vm = Parslet::Bytecode::VM.new
        vm.run(program, input).should == result
      end 
    end
  end
end