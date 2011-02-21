require File.dirname(__FILE__) + '/../spec_helper'

require 'parslet'

describe "Regressions from real examples" do
  # This parser piece produces on the left a subtree that is keyed (a hash)
  # and on the right a subtree that is a repetition of such subtrees. I've
  # for now decided that these would merge into the repetition such that the
  # return value is an array. This avoids maybe loosing keys/values in a 
  # hash merge. 
  #
  class ArgumentListParser
    include Parslet

    rule :argument_list do
      expression.as(:argument) >> 
        (comma >> expression.as(:argument)).repeat
    end
    rule :expression do
      string
    end
    rule :string do
      str('"') >> 
      (
        str('\\') >> any |
        str('"').absnt? >> any
      ).repeat.as(:string) >>
      str('"') >> space?
    end
    rule :comma do
      str(',') >> space?
    end
    rule :space? do
      space.maybe
    end
    rule :space do
      match("[ \t]").repeat(1)
    end
    
    def parse(str)
      argument_list.parse(str)
    end
  end
  describe ArgumentListParser do
    let(:instance) { ArgumentListParser.new }
    it "should have method expression" do
      instance.should respond_to(:expression)
    end 
    it 'should parse "arg1", "arg2"' do
      result = ArgumentListParser.new.parse('"arg1", "arg2"')
      
      result.should have(2).elements
      result.each do |r|
        r[:argument]
      end
    end
    it 'should parse "arg1", "arg2", "arg3"' do
      result = ArgumentListParser.new.parse('"arg1", "arg2", "arg3"')
      
      result.should have(3).elements
      result.each do |r|
        r[:argument]
      end
    end
  end

  class ParensParser < Parslet::Parser
    rule(:balanced) {
      str('(').as(:l) >> balanced.maybe.as(:m) >> str(')').as(:r)
    }
  
    root(:balanced)
  end
  describe ParensParser do
    let(:instance) { ParensParser.new }
    
    context "statefulness: trying several expressions in sequence" do
      it "should not be stateful" do
        # NOTE: Since you've come here to read this, I'll explain why
        # this is broken and not fixed: You're looking at the tuning branch, 
        # which rewrites a bunch of stuff - so I have failing tests to 
        # remind me of what is left to be done. And to remind you not to 
        # trust this code. 
        instance.parse('(())')
        lambda {
          instance.parse('((()))')
          instance.parse('(((())))')
        }.should_not raise_error(Parslet::ParseFailed)
      end 
    end
    context "expression '(())'" do
      let(:result) { instance.parse('(())') }

      it "should yield a doubly nested hash" do
        result.should be_a(Hash)
        result.should have_key(:m)
        result[:m].should be_a(Hash)   # This was an array earlier
      end 
      context "inner hash" do
        let(:inner) { result[:m] }
        
        it "should have nil as :m" do
          inner[:m].should be_nil
        end 
      end
    end
  end

  class ALanguage < Parslet::Parser
    root(:expressions)

    rule(:expressions) { (line >> eol).repeat(1) | line }
    rule(:line) { space? >> an_expression.as(:exp).repeat }
    rule(:an_expression) { str('a').as(:a) >> space? }

    rule(:eol) { space? >> match["\n\r"].repeat(1) >> space? }

    rule(:space?) { space.repeat }
    rule(:space) { multiline_comment.as(:multi) | line_comment.as(:line) | str(' ') }

    rule(:line_comment) { str('//') >> (match["\n\r"].absnt? >> any).repeat }
    rule(:multiline_comment) { str('/*') >> (str('*/').absnt? >> any).repeat >> str('*/') }
  end
  describe ALanguage do
    def remove_indent(s)
      s.to_s.lines.map { |l| l.chomp.strip }.join("\n")
    end
    
    it "should count lines correctly" do
      begin
        subject.parse('
          a 
          a a a 
          aaa // ff
          /* 
          a
          */
          b
        ')
      rescue => ex
      end
      remove_indent(subject.error_tree).should == remove_indent(%q(
        `- Unknown error in (LINE EOL){1, } / LINE
           |- Failed to match sequence (LINE EOL) at line 8 char 11.
           |  `- Failed to match sequence (SPACE? [\n\r]{1, }) at line 8 char 11.
           |     `- Expected at least 1 of [\n\r] at line 8 char 11.
           |        `- Failed to match [\n\r] at line 8 char 11.
           `- Unknown error in SPACE? exp:AN_EXPRESSION{0, }
              `- Failed to match sequence (a:'a' SPACE?) at line 8 char 11.
                 `- Expected "a", but got "b" at line 8 char 11.).strip)
    end 
  end

  class BLanguage < Parslet::Parser
    root :expression
    rule(:expression) { b.as(:one) >> b.as(:two) }
    rule(:b) { str('b') }
  end
  describe BLanguage do
    it "should parse 'bb'" do
      subject.should parse('bb').as(:one => 'b', :two => 'b')
    end 
    it "should transform with binding constraint" do
      transform = Parslet::Transform.new do |t|
        t.rule(:one => simple(:b), :two => simple(:b)) { :ok }
      end
      transform.apply(subject.parse('bb')).should == :ok
    end 
  end
end