require 'spec_helper'

require 'parslet'

describe Parslet::Expression do
  include Parslet

  RSpec::Matchers.define :accept do |string|
    match do |parslet|
      begin
        parslet.parse(string)
        true
      rescue Parslet::ParseFailed
        false
      end
    end
  end
  
  describe "running a few samples" do
    [ # pattern             # input
      "'abc'",              'abc', 
      
      "'abc'?",             'abc', 
      "'abc'?",             '', 
      
      "('abc')",            'abc', 
      
      "'a' 'b'",            'ab', 
      "'a' ('b')",          'ab', 
      
      "'a' / 'b'",          'a', 
      "'a' / 'b'",          'b', 
    ].each_slice(2) do |pattern, input|
      context "exp(#{pattern.inspect})" do
        subject { exp(pattern) }
        it { should accept(input) }
      end
    end

    [ # pattern             # input
      "'abc'",              'cba', 
      
      "'a' / 'b'",          'c', 
    ].each_slice(2) do |pattern, input|
      context "exp(#{pattern.inspect})" do
        subject { exp(pattern) }
        it { should_not accept(input) }
      end
    end
  end
end