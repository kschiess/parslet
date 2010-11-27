require 'spec_helper'

require 'parslet'

describe Parslet::Expression::Treetop do
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
  
  describe "positive samples" do
    [ # pattern             # input
      "'abc'",              'abc', 
      "...",                'abc', 
      
      "'abc'?",             'abc', 
      "'abc'?",             '', 
      
      "('abc')",            'abc', 
      
      "'a' 'b'",            'ab', 
      "'a' ('b')",          'ab', 
      
      "'a' / 'b'",          'a', 
      "'a' / 'b'",          'b', 
      
      "'a'*",               'aaa', 
      "'a'*",               '', 

      "'a'+",               'aa', 
      "'a'+",               'a', 
    ].each_slice(2) do |pattern, input|
      context "exp(#{pattern.inspect})" do
        subject { exp(pattern) }
        it { should accept(input) }
      end
    end
  end
  describe "negative samples" do
    [ # pattern             # input
      "'abc'",              'cba', 
      
      "'a' / 'b'",          'c', 
      
      "'a'+",               '',
    ].each_slice(2) do |pattern, input|
      context "exp(#{pattern.inspect})" do
        subject { exp(pattern) }
        it { should_not accept(input) }
      end
    end
  end
end