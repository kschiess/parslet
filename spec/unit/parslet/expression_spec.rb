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
  
  context "simple strings ('abc')" do
    subject { exp("'abc'") }
    it { should accept('abc') }
  end
end