require 'spec_helper'

describe Parslet::Atoms do
  include Parslet
  let(:visitor) { flexmock(:visitor) }
  
  describe Parslet::Atoms::Str do
    let(:parslet) { str('foo') }
    it "should call back visitor" do
      visitor.should_receive(:str).with('foo').once
      
      parslet.accept(visitor)
    end 
  end
  describe Parslet::Atoms::Re do
    let(:parslet) { match['abc'] }
    it "should call back visitor" do
      visitor.should_receive(:re).with('[abc]').once
      
      parslet.accept(visitor)
    end 
  end
  describe Parslet::Atoms::Sequence do
    let(:parslet) { str('a') >> str('b') }
    it "should call back visitor" do
      visitor.should_receive(:sequence).with(Array).once
      
      parslet.accept(visitor)
    end 
  end
  describe Parslet::Atoms::Repetition do
    let(:parslet) { str('a').repeat(1,2) }
    it "should call back visitor" do
      visitor.should_receive(:repetition).with(1, 2, Parslet::Atoms::Base).once
      
      parslet.accept(visitor)
    end 
  end
  describe Parslet::Atoms::Alternative do
    let(:parslet) { str('a') | str('b') }
    it "should call back visitor" do
      visitor.should_receive(:alternative).with(Array).once
      
      parslet.accept(visitor)
    end 
  end
  describe Parslet::Atoms::Named do
    let(:parslet) { str('a').as(:a) }
    it "should call back visitor" do
      visitor.should_receive(:named).with(:a, Parslet::Atoms::Base).once
      
      parslet.accept(visitor)
    end 
  end
  describe Parslet::Atoms::Entity do
    let(:parslet) { Parslet::Atoms::Entity.new('foo', :context, lambda {}) }
    it "should call back visitor" do
      visitor.should_receive(:entity).with('foo', :context, Proc).once
      
      parslet.accept(visitor)
    end 
  end
  describe Parslet::Atoms::Lookahead do
    let(:parslet) { str('a').absnt? }
    it "should call back visitor" do
      visitor.should_receive(:lookahead).with(false, Parslet::Atoms::Base).once
      
      parslet.accept(visitor)
    end 
  end
end