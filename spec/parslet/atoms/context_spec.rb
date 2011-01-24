require 'spec_helper'

require 'stringio'

describe Parslet::Atoms::Context do
  let(:source) { StringIO.new('foobar') }
  
  context "when clean" do
    it "should return whatever the block returns" do
      subject.cache(self, source) { 1 }.should == 1
    end 
    it "should rethrow :error" do
      lambda {
        subject.cache(self, source) { throw :error, 'foo' }
      }.should throw_symbol(:error, 'foo')
    end 
  end
  context "when already called for obj and input position" do
    context "(storing success, 1)" do
      before(:each) { subject.cache(self, source) { 1 } }

      it "should return cached result" do
        subject.cache(self, source) { 2 }.should == 1
      end 
    end
    context "(storing error, 'foo')" do
      before(:each) { catch(:error) {
        subject.cache(self, source) { throw :error, 'foo' }} }

      it "should return cached result" do
        lambda {
          subject.cache(self, source) { 2 }
        }.should throw_symbol(:error, 'foo')
      end 
    end
  end
end