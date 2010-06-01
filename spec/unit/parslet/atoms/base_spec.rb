require 'spec_helper'

describe Parslet::Atoms::Base do
  let(:parslet) { Parslet::Atoms::Base.new }

  describe "<- #error" do
    context "when the io is empty" do
      it "should not raise an error" do
        begin
          parslet.send(:error, StringIO.new, 'test') 
        rescue Parslet::Atoms::ParseFailed
          # This is what error does, other exceptions are bugs in #error.
        end
      end 
    end
  end
  context "when a match succeeds" do
    context "when there is an error from a previous run" do
      before(:each) do
        begin
          parslet.send(:error, StringIO.new, 'cause') 
        rescue Parslet::Atoms::ParseFailed
        end

        parslet.cause.should == 'cause'
      end
      it "should reset the #cause to nil" do
        flexmock(parslet).
          should_receive(:try => true)
        
        parslet.apply(StringIO.new)
        
        parslet.cause?.should == false
        parslet.cause.should be_nil
      end 
    end
  end
end