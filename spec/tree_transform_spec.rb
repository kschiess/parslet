require 'spec_helper'

require 'tree_transform'

describe TreeTransform do
  attr_reader :transform
  before(:each) do
    @transform = TreeTransform.new
  end
  
  class A < Struct.new(:elt); end
  class B < Struct.new(:elt); end
  class C < Struct.new(:elt); end
  
  describe "given :_x => A.new(x)" do
    before(:each) do
      transform.rule(:_x) { |d| A.new(d[:x]) }
    end
    it "should transform 'a' into A.new('a')" do
      transform.apply('a').should == A.new('a')
    end 
  end
  describe "given rules on {:a => :_x} and {:b => :_x}" do
    before(:each) do
      transform.rule(:a => :_x) { |d| A.new(d[:x]) }
      transform.rule(:b => :_x) { |d| B.new(d[:x]) }
    end
    
    it "should transform {:a=>{:b=>'c'}} into A(B('c'))" do
      transform.apply({:a=>{:b=>'c'}}).should == A.new(B.new('c'))
    end
  end
end