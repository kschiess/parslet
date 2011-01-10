require 'spec_helper'

describe Parslet::Atoms::Base do
  let(:parslet) { Parslet::Atoms::Base.new }

  describe "<- #try(io)" do
    it "should raise NotImplementedError" do
      lambda {
        parslet.try(flexmock(:io))
      }.should raise_error(NotImplementedError)
    end 
  end
  describe "<- #error" do
    context "when the io is empty" do
      it "should not raise an error" do
        # We assert that a symbol is thrown and not an exception.
        lambda {
          parslet.send(:error, StringIO.new, 'test')
        }.should throw_symbol(:error)
      end 
    end
  end
  describe "<- #flatten_sequence" do
    [
      # 9 possibilities for making a word of 2 letters from the alphabeth of
      # A(rray), H(ash) and S(tring). Make sure that all results are valid.
      #
      ['a', 'b'], 'ab',                             # S S
      [['a'], ['b']], ['a', 'b'],                   # A A
      [{:a=>'a'}, {:b=>'b'}], {:a=>'a',:b=>'b'},    # H H
      
      [{:a=>'a'}, ['a']], [{:a=>'a'}, 'a'],         # H A
      [{:a=>'a'}, 's'],   {:a=>'a'},                # H S

      [['a'], {:a=>'a'}], ['a', {:a=>'a'}],         # A H (symmetric to H A)
      [['a'], 'b'], ['a'],                          # A S 

      ['a', {:b=>'b'}], {:b=>'b'},                  # S H (symmetric to H S)
      ['a', ['b']], ['b'],                          # S A (symmetric to A S)
      
      [nil, ['a']], ['a'],                          # handling of lhs nil
      [nil, {:a=>'a'}], {:a=>'a'},
      [['a'], nil], ['a'],                          # handling of rhs nil
      [{:a=>'a'}, nil], {:a=>'a'}
    ].each_slice(2) do |sequence, result|
      context "for " + sequence.inspect do
        it "should equal #{result.inspect}" do
          parslet.flatten_sequence(sequence).should == result
        end
      end
    end
  end
  context "when a match succeeds" do
    context "when there is an error from a previous run" do
      before(:each) do
        catch(:error) {
          parslet.send(:error, StringIO.new, 'cause') 
        }

        parslet.cause.should == 'cause'
      end
      it "should reset the #cause to nil" do
        flexmock(parslet).
          should_receive(:try => true)
        
        parslet.apply(StringIO.new)
        
        parslet.cause?.should == false
        parslet.cause.should be_nil
      end 
    end
  end
end