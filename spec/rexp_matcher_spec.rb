require 'spec_helper'

require 'rexp_matcher'

describe RExpMatcher do
  def r(obj)
    RExpMatcher.new(obj)
  end
  def match_with_bind(exp, *bindings)
    simple_matcher("match with bindings") { |given, matcher|  
      matcher.failure_message = "expected #{exp.inspect} to match #{given.inspect}, but didn't. (block wasn't called or not correctly)"
      
      expectation = flexmock(:block).
        should_receive(:call).with(*bindings).once.
        mock
      
      given.match(exp) { |*vals| expectation.call(*vals) }
      
      begin
        # Use flexmock to verify the assumption, since that allows to reuse
        # the argument matcher flexmock contains.
        flexmock_verify
      rescue => ex
        false
      else
        true
      end
    }
  end

  describe "<- #match" do
    it "should match simple strings" do
      r('aaaa').should match_with_bind(:_x, 'aaaa')
    end 
  end
end