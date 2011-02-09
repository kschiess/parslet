require 'spec_helper'

describe Parslet::Slice do
  describe "construction" do
    it "should construct from an offset and a string" do
      described_class.new('foobar', 40)
    end
    it "should construct from offset, string and parent slice" do
      parent = described_class.new('foobarfoobar', 40)
      described_class.new('foobarfoobar'.slice(0,5), 40, parent)
    end
  end
  context "('foobar', 40)" do
    let(:slice) { described_class.new('foobar', 40) }
    describe "comparison" do
      it "should be equal to other slices with the same attributes" do
        other = described_class.new('foobar', 40)
        slice.should == other
        other.should == slice
      end 
      it "should be equal to a string with the same content" do
        slice.should == 'foobar'
      end
      it "should be equal with the string on the left side" do
        'foobar'.should == slice
      end
    end
    describe "matching" do
      it "should match as a string would" do
        slice.should match(/bar/)
        slice.should match(/foo/)
        
        md = slice.match(/f(o)o/)
        md.captures.first.should == 'o'
      end
    end
    describe "offset" do
      it "should return the associated offset" do
        slice.offset.should == 40
      end
    end
    describe "slices" do
      it "should reslice its parent if available" do
        small = slice.slice(1,3)
        small.should == 'oob'
        small.parent.should == slice
        
        flexmock(small.parent).should_receive(:slice).with(1,1).once
        small.slice(0,1)
      end
      it "should return slices that have a correct offset" do
        as = slice.slice(4,1)
        as.offset.should == 44
        as.should == 'a'
      end
    end
  end
end