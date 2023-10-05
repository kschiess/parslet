require 'spec_helper'

describe Parslet::Context do
  let(:transform) do
    flexmock('transform')
  end

  def context(bindings)
    described_class.new(bindings, transform)
  end

  it "binds hash keys as variable like things" do
    context(:a => 'value').instance_eval { a }.
      should == 'value'
  end
  it "responds transform's methods" do
    transform.should_receive(:foo).and_return { :foo }
    transform.should_receive(:bar).and_return { :bar }

    c = context(:a => 'value')
    assert c.respond_to?(:foo)
    c.foo.should == :foo
    assert c.respond_to?(:bar)
    c.bar.should == :bar
  end
  it "one contexts variables aren't the next ones" do
    ca = context(:a => 'b')
    cb = context(:b => 'c')

    ca.methods.should_not include(:b)
    cb.methods.should_not include(:a)
  end

  describe 'works as a Ruby object should' do
    let(:obj) { context(a: 1) }

    it 'responds_to? :a' do
      assert obj.respond_to?(:a)
    end
    it 'includes :a in #methods' do
      obj.methods.assert.include?(:a)
    end
    it 'allows inspection' do
      obj.inspect.assert.match(/@a=1/)
    end
    it 'allows conversion to string' do
      obj.to_s.assert.match(/Parslet::Context:0x/)
    end

    context 'when the context is enhanced' do
      before(:each) do
        class << obj
          def foo
            'foo'
          end
        end
      end

      it 'responds_to correctly' do
        assert obj.respond_to?(:foo)
      end
      it 'includes :foo also in methods' do
        obj.methods.assert.include?(:foo)
      end
      it 'allows calling #foo' do
        obj.foo.assert == 'foo'
      end
    end
  end
end
