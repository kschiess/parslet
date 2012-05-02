require 'spec_helper'

describe Parslet::ErrorReporter::Deepest do
  let(:reporter) { described_class.new }
  let(:fake_source) { flexmock('source') }
  
  describe '#err' do
    before(:each) { fake_source.should_receive(:pos => 13) }
    
    it "returns the deepest cause" do
      flexmock(reporter).
        should_receive(:deepest).and_return(:deepest)
      reporter.err(fake_source, 'message').
        should == :deepest
    end 
  end
  describe '#err_at' do
    before(:each) { fake_source.should_receive(:pos => 13) }

    it "returns the deepest cause" do
      flexmock(reporter).
        should_receive(:deepest).and_return(:deepest)
      reporter.err(fake_source, 'message', 13).
        should == :deepest
    end
  end
end