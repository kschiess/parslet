require 'spec_helper'

describe "Unconsumed input:" do
  class RepeatingBlockParser < Parslet::Parser
    root :expressions
    rule(:expressions) { expression.repeat }
    rule(:expression) { str('(') >> aab >> str(')') }
    rule(:aab) { str('a').repeat(1) >> str('b') }
  end
  describe RepeatingBlockParser do
    let(:parser) { described_class.new }
    it "throws annotated error" do
      error = catch_failed_parse { parser.parse('(aaac)') }
    end
    it "doesn't error out if prefix is true" do
      expect {
        parser.parse('(aaac)', :prefix => true)
      }.not_to raise_error
    end
  end

  class FindBlocksParser < Parslet::Parser
    root :blocks
    rule(:aab) { str('a').repeat(1) >> str('b') }
    rule(:block) { str('(') >> aab >> str(')') }
    rule(:blocks) { block.repeat(1) >> finished }
  end
  describe FindBlocksParser do
    let(:parser) { described_class.new }
    it "throws annotated error" do
      error = catch_failed_parse { parser.parse('(aaac)') }
    end
    it "consumes trailing content" do
      expect {
        parser.parse('(aaab)(aab)(aaaab) -- phew, three is enough!')
      }.not_to raise_error
    end
  end
end
