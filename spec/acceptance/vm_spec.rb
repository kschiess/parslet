require 'spec_helper'

describe 'VM operation' do
  extend Parslet
  
  [
    [str('foo'), 'foo']
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