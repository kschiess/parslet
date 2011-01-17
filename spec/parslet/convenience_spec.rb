require 'spec_helper'

describe 'parslet/convenience' do
  require 'parslet/convenience'
  
  class FooParser < Parslet::Parser
    rule(:foo) { str('foo') }
    root(:foo)
  end
  
  describe 'parse_with_debug' do
    before(:each) do
      @parser = flexmock FooParser.new
    end
    context 'internal' do
      before(:each) do
        # Suppress output.
        #
        @parser.should_receive(:puts).zero_or_more_times
      end
      it 'should exist' do
        lambda { @parser.parse_with_debug('anything') }.should_not raise_error(NoMethodError)
      end
      it 'should catch ParseFailed exceptions' do
        lambda { @parser.parse_with_debug('bar') }.should_not raise_error(Parslet::ParseFailed)
      end
      it 'should parse correct input like #parse' do
        lambda { @parser.parse_with_debug('foo') }.should_not raise_error
      end
    end
    context 'output' do
      it 'should puts once for the error, and once for the tree' do
        @parser.should_receive(:puts).twice
        
        @parser.parse_with_debug('incorrect')
      end
      # TODO Too specific?
      #
      # it 'should output the error and the error tree' do
      #   @parser.should_receive(:puts).once.with('Expected "foo", but got "inc" at line 1 char 1')
      #   @parser.should_receive(:puts).once.with('`- Expected "foo", but got "inc" at line 1 char 1')
      #   
      #   @parser.parse_with_debug('incorrect')
      # end
    end
    
  end
end