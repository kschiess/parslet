require 'spec_helper'

describe Parslet::Parser do
  class FooParser < Parslet::Parser
    rule(:foo) { str('foo') }
    root(:foo)
  end
  
  it "should parse 'foo'" do
    FooParser.new.parse('foo').should == 'foo'
  end 
end