require 'spec_helper'

describe Parslet::Parser do
  context "direct left recursion" do
    class InfiniteDirectLeftRecursion < Parslet::Parser
      rule(:expr) { expr }
      root(:expr)
    end

    it "raises a parse error when unresolvable" do
      parser = InfiniteDirectLeftRecursion.new()
      lambda { parser.parse("blah") }.should raise_error(Parslet::ParseFailed)
    end

    class DirectLeftRecursion < Parslet::Parser
      rule(:value) { match('[0-9]').repeat(1) }
      rule(:expr) { expr >> str('+') >> value | value }
      root(:expr)
    end

    it "correctly parses" do
      parser = DirectLeftRecursion.new
      parser.parse("1+1+2").should == '1+1+2'
    end
  end
end