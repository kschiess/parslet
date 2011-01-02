require 'spec_helper'

describe Parslet::Atoms::Sequence do
  let(:sequence) { described_class.new }
  
  describe "<- #error_tree" do
    context "when no error has been produced" do
      subject { sequence.error_tree }  
      
      its(:children) { should be_empty }
    end
  end
end