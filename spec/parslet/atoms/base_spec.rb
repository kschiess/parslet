require 'spec_helper'

describe Parslet::Atoms::Base do
  let(:parslet) { Parslet::Atoms::Base.new }
  let(:context) { Parslet::Atoms::Context.new }

  describe "<- #try(io)" do
    it "should raise NotImplementedError" do
      lambda {
        parslet.try(flexmock(:io), context)
      }.should raise_error(NotImplementedError)
    end 
  end
  describe "<- #error_tree" do
    it "should always return a tree" do
      parslet.cause.should be_nil
      parslet.error_tree.should_not be_nil
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
  describe "<- #flatten_repetition" do
    def unnamed(obj)
      parslet.flatten_repetition(obj, false)
    end
    
    it "should give subtrees precedence" do
      unnamed([[{:a=>"a"}, {:m=>"m"}], {:a=>"a"}]).should == [{:a=>"a"}]
    end 
  end
  
  context "when the parse fails, the exception" do
    it "should contain a string" do
      begin
        Parslet.str('foo').parse('bar')
      rescue Parslet::ParseFailed => ex
        ex.message.should be_kind_of(String)
      end
    end 
  end
  context "when not all input is consumed" do
    let(:parslet) { Parslet.str('foo') }
    it "should raise with a proper error message" do
      begin
        parslet.parse('foobar')
      rescue Parslet::ParseFailed => ex
        ex.message.should == "Don't know what to do with bar at line 1 char 4."
      end
    end 
  end
  context "when a match succeeds" do
    context "when there is an error from a previous run" do
      before(:each) do
        catch(:error) {
          parslet.send(:error, Parslet::Source.new('test'), 'cause') 
        }

        parslet.cause.should == "cause at line 1 char 1."
      end
      it "should reset the #cause to nil" do
        success = flexmock(:success, :error? => false)
        flexmock(parslet).
          should_receive(:try => success)
        
        parslet.apply(Parslet::Source.new(''), context)
        
        parslet.cause?.should == false
        parslet.cause.should be_nil
      end 
    end
  end
end