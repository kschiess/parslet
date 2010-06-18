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
end