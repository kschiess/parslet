require 'spec_helper'

describe Parslet::Source::Range do
  describe "<- #size" do
    let(:buffer) { Parslet::Source::Buffer.new(10, " "*100) }
    let(:range) { described_class.new(20, 2, buffer) }
    it "should return the size of the slice" do
      range.size.should == 2
    end

    context "when the buffer is smaller than the demand" do
      let(:buffer) { Parslet::Source::Buffer.new(10, '') }
      let(:range) { described_class.new(10, 2, buffer) }
      
      it "should return actual size" do
        range.size.should == 0 
      end
    end 
  end
  describe "<- #to_s" do
    let(:buffer) { Parslet::Source::Buffer.new(10, "abcdef") }
    let(:range) { described_class.new(11, 2, buffer) }
    it "should return a slice" do
      range.should == "bc"
    end 
  end
  describe "==" do
    let(:buffer) { Parslet::Source::Buffer.new(10, "abcdef") }
    let(:range) { described_class.new(11, 2, buffer) }
    
    it "should allow direct string comparison" do
      range.should == 'bc'
    end 
  end
  
end