require 'spec_helper'

describe Parslet::Atoms::Predicate do
  include Parslet
  
  context "str('foo').pred { ... }" do
    before(:each) { flexmock(self).should_receive(:pred => true).by_default }
    let(:predicate) { described_class.new(str('foo')) { |m| pred(m) } }  
    
    describe "#to_s" do
      subject { predicate.to_s }
      it { should == "'foo' &{ .. }" }
    end
    describe "#error_tree" do
      before(:each) { predicate.parse('bar') rescue nil }
      it "should return a valid error tree" do
        predicate.error_tree
      end 
    end
    
    context "when the predicate returns false" do
      before(:each) { flexmock(self).should_receive(:pred => false) }
      it "should not match 'foo'" do
        predicate.should_not parse('foo')
      end 
    end
    context "when the predicate returns true" do
      before(:each) { flexmock(self).should_receive(:pred => true) }
      it "should not match 'foo'" do
        predicate.should parse('foo')
      end 
    end
  end
  context "str('a').as(:b).repeat.pred { ... }" do
    # before(:each) { flexmock(self).should_receive(:pred => true).by_default }
    let(:parslet)   { str('a').as(:b).repeat }
    let(:predicate) { described_class.new(parslet) { |m| pred(m) } }  

    context "when fed 'aa', the block" do
      def pred(m)
        p m
      end
      it "should receive :b => 'aa' as argument" do
        flexmock(self).
          should_receive(:pred).with([{:b=>"a"}, {:b=>"a"}]).
          and_return(true).once
          
        predicate.parse('aa')
      end
    end 
  end
end