require 'spec_helper'

describe "Parslet combinations" do
  include Parslet

  RSpec::Matchers.define :parse do |string|
    match do |parslet|
      begin
        parslet.parse(string)
        true
      rescue Parslet::ParseFailed
        false
      end
    end
  end

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