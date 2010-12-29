require 'spec_helper'

describe Parslet do
  include Parslet
  
  describe "<- .root" do
    let(:root_parslet) { flexmock() }
    root :root_parslet
    
    it "should have defined a 'parse' method in the current context" do
      root_parslet.should_receive(:parse).with('snaf').once
      parse('snaf')
    end 
    it "should have defined a 'root' method, returning the root" do
      root.should == root_parslet
    end 
  end
  describe "<- .rule" do
    # Rules define methods. This can be easily tested by defining them right 
    # here. 
    context "empty rule" do
      rule(:empty) { }
      
      it "should raise a NotImplementedError" do
        lambda {
          empty.parslet
        }.should raise_error(NotImplementedError)
      end 
    end
    
    context "containing 'any'" do
      rule(:any_rule) { any }
      subject { any_rule }
      
      it { should be_a Parslet::Atoms::Entity }
      it "should memoize the returned instance" do
        any_rule.object_id.should == any_rule.object_id
      end 
    end
  end
end