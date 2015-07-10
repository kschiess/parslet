require 'spec_helper'

describe Parslet::Context do
  def context(*args)
    described_class.new(*args)
  end

  it "binds hash keys as variable like things" do
    context(:a => 'value').instance_eval { a }.
      should == 'value'
  end
  describe 'when a method in BasicObject is inherited from the environment somehow' do
    before(:each) { BasicObject.send(:define_method, :a) { 'c' } }
    after(:each) { BasicObject.send(:undef_method, :a) }

    it "masks what is already on blank slate" do
      context(:a => 'b').instance_eval { a }.
        should == 'b'
    end
  end
  it "should not reveal define_singleton_method for all users of BasicObject, just for us" do
    expect {
      BasicObject.new.instance_eval {
        define_singleton_method(:foo) { 'foo' }
      }
    }.to raise_error(NoMethodError)
  end
  it "one contexts variables aren't the next ones" do
    ca = context(:a => 'b')
    cb = context(:b => 'c')

    ca.methods.should_not include(:b)
    cb.methods.should_not include(:a)
  end
end
