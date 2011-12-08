require 'spec_helper'

describe 'VM operation' do
  extend Parslet
  include Parslet
  
  # Compiles the parser and runs it through the VM with the given input. 
  #
  def vm_parse(parser, input)
    compiler = Parslet::Bytecode::Compiler.new
    program = compiler.compile(parser)
    
    vm = Parslet::Bytecode::VM.new(true)
    vm.run(program, input)
  end
  
  # Checks if the VM code parses input the same as if you did
  # parser.parse(input).
  def vm_parses(parser, input)
    result = parser.dup.parse(input)
    
    vm_result = vm_parse(parser, input)
    
    vm_result.should == result
  end
  
  # Checks if the VM correctly fails on applying parser to input. 
  #
  def vm_fails(parser, input)
    exception = catch_exception {
      parser.dup.parse(input)
    }

    vm_exception = catch_exception {
      vm_parse(parser, input)
    }
    
    vm_exception.should_not be_nil
    vm_exception.message.should == exception.message
    vm_exception.class.should == exception.class
  end
  def catch_exception
    begin
      yield
    rescue => exception
    end
    exception
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
    describe 'repetition' do
      it "parses" do
        vm_parses str('a').repeat, 'aaa'
      end 
    end
  end
  describe 'error handling' do
    it "errors out when source is not read completely" do
      vm_fails str('fo'), 'foo'
    end
    it "generates the helpful unconsumed error (with a cause)" do
      vm_fails str('a').repeat(1), 'a.'
    end 
    it "generates the correct error tree for simple string mismatch" do
      vm_fails str('foo'), 'bar'
    end 
  end
end