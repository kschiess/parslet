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

  RSpec::Matchers.define :accept do |string|
    match do |parslet|
      begin
        parslet.parse(string)
        true
      rescue Parslet::ParseFailed
        false
      end
    end
  end
  
  describe "running a few samples" do
    [ # pattern             # input
      "'abc'",              'abc', 
      
      "'abc'?",             'abc', 
      "'abc'?",             '', 
    ].each_slice(2) do |pattern, input|
      context "exp(#{pattern})" do
        subject { exp(pattern) }
        it { should accept(input) }
      end
    end
  end
end