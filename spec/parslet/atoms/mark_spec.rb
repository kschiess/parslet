require "spec_helper"

describe Parslet::Atoms::Mark do
  include Parslet

  it "should parses forward successfully" do
    res = ( str('a').mark.as(:mark) >> str('a').as(:real) ).parse('a')
    res.keys.should == [:mark, :real]
    res[:mark].to_s.should == 'a'
    res[:real].to_s.should == 'a'
  end

  it "should parses backward successfully" do
    res = ( str('a').as(:real) >> str('a').mark(-1).as(:mark) ).parse('a')
    res.keys.should == [:real, :mark]
    res[:real].to_s.should == 'a'
    res[:mark].to_s.should == 'a'
  end
end
