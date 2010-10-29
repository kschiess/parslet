require 'spec_helper'

describe Parslet::Atoms::Entity do
  context "when constructed with str('bar') inside" do
    let(:named) { Parslet::Atoms::Entity.new('name', self, proc { Parslet.str('bar') }) }

    it "should parse 'bar' without raising exceptions" do
      named.parse('bar')
    end 
    it "should raise when applied to 'foo'" do
      lambda {
        named.parse('foo')
      }.should raise_error(Parslet::ParseFailed)
    end 

    describe "#inspect" do
      it "should return the name of the entity" do
        named.inspect.should == 'NAME'
      end 
    end
  end
  context "when constructed with empty block" do
    let(:entity) { Parslet::Atoms::Entity.new('name', self, proc { }) }
    
    it "should raise NotImplementedError" do
      lambda {
        entity.parse('some_string')
      }.should raise_error(NotImplementedError)
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