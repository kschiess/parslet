require 'spec_helper'

describe "Parslet combinations" do
  include Parslet

  describe "repeat" do
    let(:parslet) { str('a') }
    
    describe "(min, max)" do
      subject { parslet.repeat(1,2) }
      
      it { should_not parse("") }
      it { should parse("a") }
      it { should parse("aa") }
    end
  end
end