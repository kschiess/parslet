require 'spec_helper'

describe Parslet::Source::RangeSearch do
  describe "<- #lbound" do
    context "for a simple array" do
      let(:ary) { [10, 20, 30, 40, 50] }
      before(:each) { ary.extend Parslet::Source::RangeSearch }

      it "should return correct answers for numbers not in the array" do
        ary.lbound(5).should == 0
        ary.lbound(15).should == 1
        ary.lbound(25).should == 2
        ary.lbound(35).should == 3
        ary.lbound(45).should == 4
      end
      it "should return correct answers for numbers in the array" do
        ary.lbound(10).should == 1
        ary.lbound(20).should == 2
        ary.lbound(30).should == 3
        ary.lbound(40).should == 4
      end
      it "should cover right edge case" do
        ary.lbound(50).should be_nil
        ary.lbound(51).should be_nil
      end 
      it "should cover left edge case" do
        ary.lbound(0).should == 0
      end
    end
    context "for an empty array" do
      let(:ary) { [] }
      before(:each) { ary.extend Parslet::Source::RangeSearch }

      it "should return nil" do
        ary.lbound(1).should be_nil
      end 
    end
  end
end