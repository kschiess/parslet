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
      it "should be equal to other slices (offset is irrelevant for comparison)" do
        other = described_class.new('foobar', 41)
        slice.should == other
        other.should == slice
      end 
      it "should be equal to a string with the same content" do
        slice.should == 'foobar'
      end
      it "should be equal to a string (inversed operands)" do
        'foobar'.should == slice
      end 
      it "should not be equal to a string" do
        slice.should_not equal('foobar')
      end 
      it "should not be eql to a string" do
        slice.should_not eql('foobar')
      end 
      it "should not hash to the same number" do
        slice.hash.should_not == 'foobar'.hash
      end 
    end
    describe "offset" do
      it "should return the associated offset" do
        slice.offset.should == 40
      end
    end
    describe "slices" do
      describe "<- #slice(start, length)" do
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
      describe "<- #abs_slice(offset, length)" do
        it "should call relative slice with the correct offsets" do 
          flexmock(slice).should_receive(:slice).with(1,1).once
          slice.abs_slice(41, 1)
        end 
      end
    end
    describe "satisfies? test" do
      it "should answer true if offset/length is within the slice" do
        slice.satisfies?(40, 5).should == true
        slice.satisfies?(41, 1).should == true
        slice.satisfies?(45, 1).should == true
      end 
      it "should answer false otherwise" do
        slice.satisfies?(39, 3).should == false
        slice.satisfies?(40, 10).should == false
      end 
    end
    describe "string methods" do
      describe "matching" do
        it "should match as a string would" do
          slice.should match(/bar/)
          slice.should match(/foo/)

          md = slice.match(/f(o)o/)
          md.captures.first.should == 'o'
        end
      end
      describe "<- #size" do
        subject { slice.size }
        it { should == 6 } 
      end
      describe "<- #+(other)" do
        it "should return a slice that represents the extended range" do
          other = described_class.new('foobar', 46)
          (slice + other).should eq(described_class.new('foobarfoobar', 40))
        end
        it "should fail when adding slices that aren't adjacent" do
          other = described_class.new('foobar', 100)
          lambda { slice + other 
            }.should raise_error(Parslet::InvalidSliceOperation)
        end
        context "when slices stem from a bigger buffer" do
          let(:buffer) { described_class.new('foobarfoobar', 10) }
          let!(:slice1) { buffer.slice(0,3) }
          let!(:slice2) { buffer.slice(3,3) }
          it "should reslice instead of concatenating" do
            flexmock(buffer).should_receive(:abs_slice).with(10,6).once
            slice1 + slice2
          end
        end  
      end
    end
    describe "conversion" do
      describe "<- #to_slice" do
        it "should return self" do
          slice.to_slice.should eq(slice)
        end 
      end
      describe "<- #to_sym" do
        it "should return :foobar" do
          slice.to_sym.should == :foobar
        end 
      end
      describe "cast to Float" do
        it "should return a float" do
          Float(described_class.new('1.345', 11)).should == 1.345
        end 
      end
      describe "cast to Integer" do
        it "should cast to integer as a string would" do
          s = described_class.new('1234', 40)
          Integer(s).should == 1234
          s.to_i.should == 1234
        end 
        it "should fail when Integer would fail on a string" do
          lambda { Integer(slice) }.should raise_error
        end 
        it "should turn into zero when a string would" do
          slice.to_i.should == 0
        end 
      end
    end
  end
end