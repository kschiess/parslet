require 'spec_helper'

describe 'Result of a Parslet#parse' do
  include Parslet; extend Parslet
  
  describe "regression" do
    [
      # Behaviour with maybe-nil
      [str('foo').maybe >> str('bar'), "bar", "bar"],
      [str('bar') >> str('foo').maybe, "bar", 'bar'], 
      
      # These might be hard to understand; look at the result of str.maybe >> str
      # and str.maybe >> str first. 
      [(str('f').maybe >> str('b')).repeat, "bb", "bb"],
      [(str('b') >> str('f').maybe).repeat, "bb", 'bb']
      
    ].each do |parslet, input, result|
      context "#{parslet.inspect}" do
        it "should parse \"#{input}\" into \"#{result}\"" do
          parslet.parse(input).should == result
        end
      end
    end

  end

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