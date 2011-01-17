require 'spec_helper'

describe Parslet::Source do
  let(:io) { StringIO.new("a"*100 + "\n" + "a"*100 + "\n") }
  let(:source) { described_class.new(io) }
  
  describe "<- #read(n)" do
    it "should return 100 'a's when reading a kilobyte" do
      source.read(100).should == 'a'*100
    end
  end
  describe "<- #eof?" do
    subject { source.eof? }
    
    it { should be_false }
    context "after depleting the source" do
      before(:each) { source.read(10000) }
      
      it { should be_true }
    end
  end
  describe "<- #pos" do
    subject { source.pos }
    
    it { should == 0 }
    context "after reading a few bytes" do
      it "should still be correct" do
        pos = 0
        10.times do
          pos += n = rand(10)
          source.read(n)
          
          source.pos.should == pos
        end
      end 
    end
  end
  describe "<- #pos=(n)" do
    subject { source.pos }
    10.times do
      pos = rand(200)
      context "setting position #{pos}" do
        before(:each) { source.pos = pos }
        
        it { should == pos }
      end
    end
  end
  describe "<- #column & #line" do
    subject { source.line_and_column }
    
    it { should == [1,1] }
    
    context "on the first line" do
      it "should increase column with every read" do
        10.times do |i|
          source.line_and_column.last.should == 1+i
          source.read(1)
        end
      end 
    end
    context "on the second line" do
      before(:each) { source.read(101) }
      it { should == [2, 1]}
    end
    context "after reading everything" do
      before(:each) { source.read(10000) }

      it "should contain all line ends" do
        source.line_ends.should == [101, 202]
      end 
      
      context "when seeking to 9" do
        before(:each) { source.pos = 9 }
        it { should == [1, 10] }
      end
      context "when seeking to 100" do
        before(:each) { source.pos = 100 }
        it { should == [1, 101] }
      end
      context "when seeking to 101" do
        before(:each) { source.pos = 101 }
        it { should == [2, 1] }
      end
      context "when seeking to 102" do
        before(:each) { source.pos = 102 }
        it { should == [2, 2] }
      end
    end
    context "reading char by char, storing the results" do
      before(:each) { 
        @results = {}
        while not source.eof?
          pos = source.pos
          @results[pos] = source.line_and_column
          source.read(1)
        end
        
        @results.should have(202).entries
      }
      
      it "should give the same results when seeking" do
        @results.each do |pos, result|
          source.pos = pos
          source.line_and_column.should == result
        end
      end
    end
  end
  describe "<- #line_ends" do
    subject { source.line_ends }
    context "after reading 101 chars" do
      before(:each) { source.read(101) }
      
      it { should == [101] }
    end
  end
end