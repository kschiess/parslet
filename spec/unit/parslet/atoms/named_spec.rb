require 'spec_helper'

describe Parslet::Atoms::Named do
  let(:hosted) { flexmock(:parslet, :error_tree => :hosted_tree) }
  let(:parslet) { Parslet::Atoms::Named.new(hosted, 'name')}
  
  describe "<- #error_tree" do
    let(:result) { parslet.error_tree }
    it "should return the hosted parslet's tree" do
      result.should == :hosted_tree
    end 
  end
end