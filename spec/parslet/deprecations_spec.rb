require "spec_helper"

describe "deprecations" do

  include Parslet
  extend Parslet

  let(:atom) do
    str('string')
  end

  describe "#absnt?" do
    it "is deprecated" do
      flexmock(Parslet).should_receive(:warn_deprecation).once
      atom.absnt?
    end
  end

  describe "#prsnt?" do
    it "is deprecated" do
      flexmock(Parslet).should_receive(:warn_deprecation).once
      atom.prsnt?
    end
  end

end
