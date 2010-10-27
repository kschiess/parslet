require 'spec_helper'

describe Parslet::Atoms::Entity do
  let(:named) { Parslet::Atoms::Entity.new('name', self, proc { Parslet.str('bar') }) }

  it "should parse 'bar' without raising exceptions" do
    named.parse('bar')
  end 

  describe "#inspect" do
    it "should return the name of the entity" do
      named.inspect.should == 'NAME'
    end 
  end
  
  context "recursive definition parser" do
    class RecDefParser
      include Parslet
      rule :recdef do
        str('(') >> atom >> str(')')
      end
      rule :atom do
        str('a') / str('b') / recdef
      end
    end
    let(:parser) { RecDefParser.new }
    
    it "should parse balanced parens" do
      parser.recdef.parse("(((a)))")
    end
    it "should not throw 'stack level too deep' when printing errors" do
      begin
        parser.recdef.parse('(((a))')
      rescue Parslet::ParseFailed
      end
      parser.recdef.error_tree.ascii_tree
    end
  end
end