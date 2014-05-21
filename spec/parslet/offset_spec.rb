require 'spec_helper'

describe Parslet::Parser do
  include Parslet
  
  # string = "‡ 1. A compound representing α1 adrenergic receptor.‡"
  string = "‡ 1."
  class FooParser < Parslet::Parser
    rule(:space)  { match['[:space:]'].repeat(1) }
    rule(:number) {
      str('‡') >>
      space >>
      match['\d'].repeat(1).as(:number) >> str('.')
    }
    root(:number)
  end
  
  it "should parse 'string' with coreect offset" do
    parsed = FooParser.new.parse(string)
    parsed[:number].offset.should == 2
  end 
end