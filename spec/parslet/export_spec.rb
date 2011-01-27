require 'spec_helper'

describe Parslet::Parser, "exporting to other lingos" do
  class MiniLisp < Parslet::Parser
    root :expression
    rule(:expression) {
      space? >> str('(') >> space? >> body >> str(')')
    }
    
    rule(:body) {
      (expression | identifier | float | integer | string).repeat.as(:exp)
    }
    
    rule(:space) {
      match('\s').repeat(1)
    }
    rule(:space?) {
      space.maybe
    }
    
    rule(:identifier) { 
      (match('[a-zA-Z=*]') >> match('[a-zA-Z=*_]').repeat).as(:identifier) >> space?
    }
    
    rule(:float) { 
      (
        integer >> (
          str('.') >> match('[0-9]').repeat(1) |
          str('e') >> match('[0-9]').repeat(1)
        ).as(:e)
      ).as(:float) >> space?
    }
    
    rule(:integer) {
      ((str('+') | str('-')).maybe >> match("[0-9]").repeat(1)).as(:integer) >> space?
    }
    
    rule(:string) {
      str('"') >> (
        str('\\') >> any |
        str('"').absnt? >> any 
      ).repeat.as(:string) >> str('"') >> space?
    }
  end

  describe "<- #to_citrus" do
    let(:citrus) { File.read(
      File.join(File.dirname(__FILE__), 'minilisp.citrus'))
    }
    it "should be valid citrus syntax" do
      MiniLisp.new.to_citrus.should == citrus 
    end 
  end
end