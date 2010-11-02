require 'spec_helper'

require 'parslet'

describe Parslet::Expression do
  include Parslet

  examples = <<-EXPRESSION_EXAMPLES
    'a'
  EXPRESSION_EXAMPLES
  
  examples.lines.each do |example|
    example = example.strip.chomp
    context "[#{example}]" do
      it "should parse without exception" do
        exp = Parslet::Expression.new(example)
      end 
    end
  end

  # REPLACE ME TODO
  def match(str)
    simple_matcher("match") do |parslet|
      parslet.parse(str)
    end
  end
  
  context "simple strings ('abc')" do
    subject { exp("'abc'") }
    it { should match('abc') }
  end
end