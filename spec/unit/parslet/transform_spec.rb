require 'spec_helper'

require 'parslet'

describe Parslet::Transform do
  include Parslet
  
  attr_reader :transform
  before(:each) do
    @transform = Parslet::Transform.new
  end
  
  class A < Struct.new(:elt); end
  class B < Struct.new(:elt); end
  class C < Struct.new(:elt); end
  class Bi < Struct.new(:a, :b); end
  
  describe "given simple(:x) => A.new(x)" do
    before(:each) do
      transform.rule(simple(:x)) { |d| A.new(d[:x]) }
    end
    
    it "should transform 'a' into A.new('a')" do
      transform.apply('a').should == A.new('a')
    end 
    it "should transform ['a', 'b'] into [A.new('a'), A.new('b')]" do
      transform.apply(['a', 'b']).should == 
        [A.new('a'), A.new('b')]
    end
  end
  describe "given rules on {:a => simple(:x)} and {:b => :_x}" do
    before(:each) do
      transform.rule(:a => simple(:x)) { |d| A.new(d[:x]) }
      transform.rule(:b => simple(:x)) { |d| B.new(d[:x]) }
    end
    
    it "should transform {:d=>{:b=>'c'}} into d => B('c')" do
      transform.apply({:d=>{:b=>'c'}}).should == {:d => B.new('c')}
    end
    it "should transform {:a=>{:b=>'c'}} into A(B('c'))" do
      transform.apply({:a=>{:b=>'c'}}).should == A.new(B.new('c'))
    end
  end
  describe "pulling out subbranches" do
    before(:each) do
      transform.rule(:a => {:b => simple(:x)}, :d => {:e => simple(:y)}) { |d|
        Bi.new(*d.values_at(:x, :y))
      }
    end
    
    it "should yield Bi.new('c', 'f')" do
      transform.apply(:a => {:b => 'c'}, :d => {:e => 'f'}).should ==
        Bi.new('c', 'f')
    end 
  end
end