require 'spec_helper'

require 'parslet/atoms/transform'

describe Parslet::Atoms::Transform do
  include Parslet
  
  context "when used directly" do
    it "should transform all inputs onto itself"  
  end
  
  class ModifyAll < Parslet::Atoms::Transform
    def visit_str(s)
      super(s.reverse)
    end
    def visit_sequence(seq)
      super(seq.reverse)
    end
  end
  describe ModifyAll do
    subject { ModifyAll.new }
    def apply(grammar)
      subject.apply(grammar)
    end
    
    context "str" do
      it "should reverse the string" do
        apply(str('foo')).should parse('oof')
      end 
    end
    context "sequence" do
      it "should reverse sequences" do
        apply(str('a') >> str('b')).should parse('ba')
      end 
    end
  end
  
end