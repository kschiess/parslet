require 'spec_helper'

describe 'VM operation' do
  extend Parslet
  include Parslet
  
  # Compiles the parser and runs it through the VM with the given input. 
  #
  def vm_parse(parser, input)
    compiler = Parslet::Bytecode::Compiler.new
    program = compiler.compile(parser)
    
    vm = Parslet::Bytecode::VM.new(false)
    vm.run(program, input)
  end
  
  # Checks if the VM code parses input the same as if you did
  # parser.parse(input).
  def vm_parses(parser, input)
    exception = nil
    begin
      result = parser.dup.parse(input)
    rescue => exception
    end
    
    vm_exception = nil
    begin
      vm_result = vm_parse(parser, input)
    rescue => vm_exception
    end
    
    if exception
      vm_exception.should be_kind_of(exception.class)
      vm_exception.message.should == exception.message
    else
      vm_result.should == result
    end
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
  describe 'error handling' do
    it "errors out when source is not read completely" do
      vm_parses str('fo'), 'foo'
    end
    it "generates the correct error tree for simple string mismatch" do
      vm_parses str('foo'), 'bar'
    end 
  end
end