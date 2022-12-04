# Encoding: UTF-8

require 'spec_helper'

require 'parslet'

describe "Mixing parsers using alternate" do
  class MixedParsersParser
    include Parslet

    rule(:parser1) do
      str("a") >> match('\d').repeat(1).as(:number) >> (str(":") >> match('\d').repeat(4, 4).as(:year)).maybe
    end

    rule(:parser2) do
      str("a") >> match('\d').repeat(1).as(:number) >> (str(" Edition").as(:edition)).maybe
    end

    rule(:failing_rule_example) do
      str("(") >> ((parser1 | parser2) >> str(", ").maybe).repeat(1) >> str(")")
    end

    rule(:mixed_parsers) do
      parser1 | parser2
    end

    rule(:identifiers) do
      str("(") >> (match('[^),]').repeat(1).as(:identifier) >> str(", ").maybe).repeat(1) >> str(")")
    end

    def two_pass_parsing(code)
      TransformIdentifiers.new.apply(MixedParsersParser.new.identifiers.parse(code))
    end

  end

  class TransformIdentifiers < Parslet::Transform
    rule(:identifier => simple(:identifier)) do |x|
      { identifier: MixedParsersParser.new.mixed_parsers.parse(x[:identifier].to_s) }
    end
  end

  describe MixedParsersParser do
    subject { MixedParsersParser.new }

    let(:should_match_parser1) { "a12345:1234" }
    let(:should_match_parser2) { "a12345 Edition" }
    let(:should_match_any_parser) { "a12345" }
    let(:should_match_both_parsers) { "(#{should_match_parser1}, #{should_match_parser2})"}

    let(:parser1_result) { subject.parser1.parse(should_match_parser1) }
    let(:parser2_result) { subject.parser2.parse(should_match_parser2) }

    it "fails with alternating parsers" do
      expect(subject.failing_rule_example).to parse("(#{should_match_any_parser})")
      expect(subject.failing_rule_example).to parse("(#{should_match_parser1})")
      expect(subject.failing_rule_example).not_to parse("(#{should_match_parser2})", trace: true)
      expect(subject.failing_rule_example).not_to parse(should_match_both_parsers, trace: true)
    end

    it "parses identifier" do
      expect(subject.identifiers.parse("(#{should_match_parser1})")).to eq([{identifier: should_match_parser1}])
    end

    it "parses several identifiers" do
      expect(subject.identifiers.parse(should_match_both_parsers))
        .to eq([{ identifier: should_match_parser1 }, { identifier: should_match_parser2 }])
    end

    it "parses using 2-level parsing" do
      expect(subject.two_pass_parsing(should_match_both_parsers))
        .to eq([{ identifier: parser1_result }, { identifier: parser2_result }])
    end
  end
end
