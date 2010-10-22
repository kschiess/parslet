require 'spec_helper'

describe 'Result of a Parslet#parse' do
  include Parslet
  
  let(:foo) { str('foo') }
  describe "foo.maybe" do
    let(:parslet) { foo.maybe }
    
    context "when given no matching input" do
      subject { parslet.parse('') }
      it { should == nil }
    end
    context "when matching" do
      subject { parslet.parse('foo') }
      it { should == 'foo' }
    end
  end
  
end