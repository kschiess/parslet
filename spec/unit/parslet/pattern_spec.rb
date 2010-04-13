require 'spec_helper'

require 'parslet'

describe Parslet::Pattern do
  include Parslet
  
  # These two factory methods help make the specs more robust to interface
  # changes. They also help to label trees (t) and patterns (p).
  def p(pattern)
    Parslet::Pattern.new(pattern)
  end
  def t(obj)
    obj
  end
  
  def match_with_bind(pattern, *bindings)
    simple_matcher("match with bindings") { |tree, matcher|  
      matcher.failure_message = "expected #{pattern.inspect} to match #{tree.inspect}, but didn't. (block wasn't called or not correctly)"
      
      expectation = flexmock(:block).
        should_receive(:call).with(*bindings).once.
        mock

      p(pattern).each_match(tree) { |*vals| expectation.call(*vals) }
      
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
      t('aaaa').should match_with_bind(simple(:x), :x => 'aaaa')
    end 

    context "simple hash {:a => 'b'}" do
      attr_reader :exp
      before(:each) do
        @exp = t(:a => 'b')
      end

      it "should match {:a => simple(:x)}, binding 'b' to the first argument" do
        exp.should match_with_bind({:a => simple(:x)}, :x => 'b')
      end 
      it "should match {:a => 'b'} with no binds" do
        exp.should match_with_bind({:a => 'b'}, {})
      end 
    end
    context "a more complex hash {:a => {:b => 'c'}}" do
      attr_reader :exp
      before(:each) do
        @exp = t(:a => {:b => 'c'})
      end
      
      it "should match partially with {:b => simple(:x)}" do
        exp.should match_with_bind({:b => simple(:x)}, :x => 'c')
      end
      it "should match wholly with {:a => {:b => simple(:x)}}" do
        exp.should match_with_bind({:a => {:b => simple(:x)}}, :x => 'c')
      end
      it "should match element wise with 'c'" do
        exp.should match_with_bind('c', {})
      end
      it "should match element wise with simple(:x)" do
        exp.should match_with_bind(simple(:x), :x => 'c')
      end
      it "should not bind subtrees to variables in {:a => simple(:x)}" do
        p(:a => simple(:x)).each_match(exp) { |args| raise args.inspect }
      end
    end
    context "an array of 'a', 'b', 'c'" do
      attr_reader :exp
      before(:each) do
        @exp = t(['a', 'b', 'c'])
      end

      it "should match each element in turn" do
        verify = flexmock().should_expect do |expect|
          expect.should_be_strict
          expect.call('a')
          expect.call('b')
          expect.call('c')
        end.mock

        p(simple(:x)).each_match(exp) { |d| 
          verify.call(d[:x]) }
      end 
      it "should match all elements at once" do
        exp.should match_with_bind(
          [simple(:x), simple(:y), simple(:z)], 
          :x => 'a', :y => 'b', :z => 'c')
      end 
    end
    context "{:a => 'a', :b => 'b'}" do
      attr_reader :exp
      before(:each) do
        @exp = t(:a => 'a', :b => 'b')
      end

      it "should match both elements simple(:x), simple(:y)" do
        exp.should match_with_bind(
          {:a => simple(:x), :b => simple(:y)}, 
          :x => 'a', :y => 'b')
      end
      it "should not match a constrained match (simple(:x) != simple(:y))"  do
        p({:a => simple(:x), :b => simple(:x)}).each_match(exp) { raise }
      end
    end
    context "{:a => 'a', :b => 'a'}" do
      attr_reader :exp
      before(:each) do
        @exp = t(:a => 'a', :b => 'a')
      end

      it "should match constrained pattern" do
        exp.should match_with_bind(
          {:a => simple(:x), :b => simple(:x)}, 
          :x => 'a')
      end
    end
    context "{:sub1 => {:a => 'a'}, :sub2 => {:a => 'a'}}" do
      attr_reader :exp
      before(:each) do
        @exp = t({
          :sub1 => {:a => 'a'}, 
          :sub2 => {:a => 'a'} 
        })
      end

      it "should verify constraints over several subtrees" do
        exp.should match_with_bind({
          :sub1 => {:a => simple(:x)}, 
          :sub2 => {:a => simple(:x)} 
        }, :x => 'a')
      end
      it "should return both bind variables simple(:x), simple(:y)" do
        exp.should match_with_bind({
          :sub1 => {:a => simple(:x)}, 
          :sub2 => {:a => simple(:y)} 
        }, :x => 'a', :y => 'a')
      end  
    end
    context "{:sub1 => {:a => 'a'}, :sub2 => {:a => 'b'}}" do
      attr_reader :exp
      before(:each) do
        @exp = t({
          :sub1 => {:a => 'a'}, 
          :sub2 => {:a => 'b'} 
        })
      end

      it "should verify constraints over several subtrees" do
        exp.should_not match_with_bind({
          :sub1 => {:a => simple(:x)}, 
          :sub1 => {:a => simple(:x)} 
        }, 'a')
      end
      it "should return both bind variables simple(:x), simple(:y)" do
        exp.should match_with_bind({
          :sub1 => {:a => simple(:x)}, 
          :sub2 => {:a => simple(:y)} 
        }, :x => 'a', :y => 'b')
      end  
    end
    context "[{:a => 'x'}, {:a => 'y'}]" do
      attr_reader :exp  
      before(:each) do
        @exp = t([{:a => 'x'}, {:a => 'y'}])
      end
      
      it "should match :a => simple(:x) repeatedly" do
        letters = []
        p(:a => simple(:x)).each_match(exp) { |d| letters << d[:x] }
        
        letters.should == %w(x y)
      end 
      it "should match simple(:x)" do
        letters = []
        p(simple(:x)).each_match(exp) { |d| letters << d[:x] }
        
        letters.should == %w{x y}
      end 
      it "should not match simple(:x)* (as a whole)" 
    end
    context "['x', 'y', 'z']" do
      attr_reader :exp  
      before(:each) do
        @exp = t(['x', 'y', 'z'])
      end

      it "should match [simple(:x), simple(:y), simple(:z)]" do
        bound = nil
        p([simple(:x), simple(:y), simple(:z)]).each_match(exp) { |d| bound=d }
        bound.should == { :x => 'x', :y => 'y', :z => 'z' }
      end
      it "should match %w(x y z)" do
        exp.should match_with_bind(%w(x y z), { })
      end 
      it "should not match [simple(:x), simple(:y), simple(:x)]" do
        p([simple(:x), simple(:y), simple(:x)]).each_match(exp) { |d| raise }
      end
      it "should not match [simple(:x), simple(:y)]" do
        p([simple(:x), simple(:y), simple(:x)]).each_match(exp) { |d| raise }
      end
      it "should match simple(:x)* (as array)" 
    end
    context "{:a => [1,2,3]}" do
      attr_reader :exp  
      before(:each) do
        @exp = t(:a => [1,2,3])
      end

      it "should match :a => sequence(:x) (binding x to the whole array)" do
        exp.should match_with_bind({:a => sequence(:x)}, {:x => [1,2,3]})
      end
    end
  end
end