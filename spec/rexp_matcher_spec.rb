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
      r('aaaa').should match_with_bind(:_x, :x => 'aaaa')
    end 

    context "{:a => 'a', :b => 'b'}" do
      attr_reader :exp
      before(:each) do
        @exp = r(:a => 'a', :b => 'b')
      end

      it "should match both elements :_x, :_y" do
        exp.should match_with_bind(
          {:a => :_x, :b => :_y}, 
          :x => 'a', :y => 'b')
      end
      it "should not match a constrained match (:_x != :_y)"  do
        exp.match({:a => :_x, :b => :_x}) { raise }
      end
    end
    context "{:a => 'a', :b => 'a'}" do
      attr_reader :exp
      before(:each) do
        @exp = r(:a => 'a', :b => 'a')
      end

      it "should match constrained pattern" do
        exp.should match_with_bind(
          {:a => :_x, :b => :_x}, 
          :x => 'a')
      end
    end
    context "{:sub1 => {:a => 'a'}, :sub2 => {:a => 'a'}}" do
      attr_reader :exp
      before(:each) do
        @exp = r({
          :sub1 => {:a => 'a'}, 
          :sub2 => {:a => 'a'} 
        })
      end

      it "should verify constraints over several subtrees" do
        exp.should match_with_bind({
          :sub1 => {:a => :_x}, 
          :sub2 => {:a => :_x} 
        }, :x => 'a')
      end
      it "should return both bind variables :_x, :_y" do
        exp.should match_with_bind({
          :sub1 => {:a => :_x}, 
          :sub2 => {:a => :_y} 
        }, :x => 'a', :y => 'a')
      end  
    end
    context "{:sub1 => {:a => 'a'}, :sub2 => {:a => 'b'}}" do
      attr_reader :exp
      before(:each) do
        @exp = r({
          :sub1 => {:a => 'a'}, 
          :sub2 => {:a => 'b'} 
        })
      end

      it "should verify constraints over several subtrees" do
        exp.should_not match_with_bind({
          :sub1 => {:a => :_x}, 
          :sub1 => {:a => :_x} 
        }, 'a')
      end
      it "should return both bind variables :_x, :_y" do
        exp.should match_with_bind({
          :sub1 => {:a => :_x}, 
          :sub2 => {:a => :_y} 
        }, :x => 'a', :y => 'b')
      end  
    end
    context "simple hash {:a => 'b'}" do
      attr_reader :exp
      before(:each) do
        @exp = r(:a => 'b')
      end

      it "should match {:a => :_x}, binding 'b' to the first argument" do
        exp.should match_with_bind({:a => :_x}, :x => 'b')
      end 
      it "should match {:a => 'b'} with no binds" do
        exp.should match_with_bind({:a => 'b'}, {})
      end 
    end
    context "a more complex hash {:a => {:b => 'c'}}" do
      attr_reader :exp
      before(:each) do
        @exp = r(:a => {:b => 'c'})
      end
      
      it "should match partially with {:b => :_x}" do
        exp.should match_with_bind({:b => :_x}, :x => 'c')
      end
      it "should match wholly with {:a => {:b => :_x}}" do
        exp.should match_with_bind({:a => {:b => :_x}}, :x => 'c')
      end
      it "should match element wise with 'c'" do
        exp.should match_with_bind('c', {})
      end
      it "should match element wise with :_x" do
        exp.should match_with_bind(:_x, :x => 'c')
      end
      it "should not bind subtrees to variables in {:a => :_x}" do
        exp.match(:a => :_x) { |args| raise args.inspect }
      end
    end
    context "an array of 'a', 'b', 'c'" do
      attr_reader :exp
      before(:each) do
        @exp = r(['a', 'b', 'c'])
      end

      it "should match each element in turn" do
        verify = flexmock().should_expect do |expect|
          expect.should_be_strict
          expect.call('a')
          expect.call('b')
          expect.call('c')
        end.mock
        
        exp.match(:_x) { |d| 
          verify.call(d[:x]) }
      end 
      it "should match all elements at once" do
        exp.should match_with_bind(
          [:_x, :_y, :_z], 
          :x => 'a', :y => 'b', :z => 'c')
      end 
    end
  end
end