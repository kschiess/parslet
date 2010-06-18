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
        (str('\\') >> any) /
        (str('"').absnt? >> any)
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
  context ArgumentListParser do
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

end