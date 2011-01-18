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
end