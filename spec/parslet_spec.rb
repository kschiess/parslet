require 'spec_helper'

require 'parslet'

describe Parslet do
  def not_parse
    raise_error(Parslet::Matchers::ParseFailed)
  end
  
  include Parslet
  extend Parslet

  def gio(str)
    StringIO.new(str)
  end
  
  describe "match('[abc]')" do
    attr_reader :parslet
    before(:each) do
      @parslet = match('[abc]')
    end
    
    it "should parse {a,b,c}" do
      parslet.parse('a')
      parslet.parse('b')
      parslet.parse('c')
    end 
    it "should not parse d" do
      lambda {
        parslet.parse('d')
      }.should raise_error(Parslet::Matchers::ParseFailed)
    end 
  end
  describe "match(['[a]').repeat(3)" do
    attr_reader :parslet
    before(:each) do
      @parslet = match('[a]').repeat(3)
    end
    
    it "should not succeed on only 'aa'" do
      lambda {
        parslet.parse('aa')
      }.should raise_error(Parslet::Matchers::ParseFailed)
    end 
    it "should succeed on 'aaa'" do
      parslet.parse('aaa')
    end 
    it "should succeed on many 'a'" do
      parslet.parse('a'*100)
    end 
  end
  describe "str('foo')" do
    attr_reader :parslet
    before(:each) do
      @parslet = str('foo')
    end
    
    it "should parse 'foo'" do
      parslet.parse('foo')
    end
    it "should not parse 'bar'"  do
      lambda {
        parslet.parse('bar')
      }.should raise_error(Parslet::Matchers::ParseFailed)
    end
  end
  describe "str('foo').maybe" do
    attr_reader :parslet
    before(:each) do
      @parslet = str('foo').maybe
    end

    it "should parse a foo" do
      parslet.parse('foo')
    end
    it "should leave pos untouched if there is no foo" do
      io = gio('bar')
      parslet.apply(io)
      io.pos.should == 0
    end
  end
  describe "str('foo') >> str('bar')" do
    attr_reader :parslet
    before(:each) do
      @parslet = str('foo') >> str('bar')
    end
    
    it "should parse 'foobar'" do
      parslet.parse('foobar')
    end
    it "should not parse 'foobaz'" do
      lambda {
        parslet.parse('foobaz')
      }.should raise_error(Parslet::Matchers::ParseFailed)
    end
    it "should return self for chaining" do
      (parslet >> str('baz')).should == parslet
    end 
  end
  describe "str('foo') / str('bar')" do
    attr_reader :parslet
    before(:each) do
      @parslet = str('foo') / str('bar')
    end
    
    it "should accept 'foo'" do
      parslet.parse('foo')
    end
    it "should accept 'bar'" do
      parslet.parse('bar')
    end
    it "should not accept 'baz'" do
      lambda {
        parslet.parse('baz')
      }.should raise_error(Parslet::Matchers::ParseFailed)
    end   
    it "should return self for chaining" do
      (parslet / str('baz')).should == parslet
    end 
  end
  describe "str('foo').prsnt? (positive lookahead)" do
    attr_reader :parslet
    before(:each) do
      @parslet = str('foo').prsnt?
    end
    
    context "when fed 'foo'" do
      it "should parse" do
        parslet.apply(gio('foo'))
      end
      it "should not change input position" do
        io = gio('foo')
        parslet.apply(io)
        io.pos.should == 0
      end
    end
    context "when fed 'bar'" do
      it "should not parse" do
        lambda { parslet.parse('bar') }.should not_parse
      end
    end
    describe "<- #parse" do
      it "should return nil" do
        parslet.apply(gio 'foo').should == nil
      end 
    end
  end
  describe "str('foo').absnt? (negative lookahead)" do
    attr_reader :parslet
    before(:each) do
      @parslet = str('foo').absnt?
    end
    
    context "when fed 'bar'" do
      it "should parse" do
        parslet.apply(gio 'bar')
      end
      it "should not change input position" do
        io = gio('bar')
        parslet.apply(io)
        io.pos.should == 0
      end
    end
    context "when fed 'foo'" do
      it "should not parse" do
        lambda { parslet.parse('foo') }.should not_parse
      end
    end
  end
  describe "any" do
    attr_reader :parslet
    before(:each) do
      @parslet = any
    end
    
    it "should match" do
      parslet.parse('.')
    end 
    it "should consume one char" do
      io = gio('foo')
      parslet.apply(io)
      io.pos.should == 1
    end 
  end

  describe "<- #as(name)" do
    context "str('foo').as(:bar)" do
      it "should return :bar => 'foo'" do
        str('foo').as(:bar).parse('foo').should == { :bar => 'foo' }
      end 
    end
    context "match('[abc]').as(:name)" do
      it "should return :name => 'b'" do
        match('[abc]').as(:name).parse('b').should == { :name => 'b' }
      end 
    end
    context "match('[abc]').repeat.as(:name)" do
      it "should return collated result ('abc')" do
        match('[abc]').repeat.as(:name).
          parse('abc').should == { :name => 'abc' }
      end
    end
    context "(str('a').as(:a) >> str('b').as(:b)).as(:c)" do
      it "should return a hash of hashes" do
        (str('a').as(:a) >> str('b').as(:b)).as(:c).
          parse('ab').should == {
            :c => {
              :a => 'a', 
              :b => 'b'
            }
          }
      end 
    end
    context "(str('a').as(:a) >> str('ignore') >> str('b').as(:b))" do
      it "should correctly flatten (leaving out 'ignore')" do
        (str('a').as(:a) >> str('ignore') >> str('b').as(:b)).
          parse('aignoreb').should == {
            :a => 'a', 
            :b => 'b'
          }
      end
    end
    
    context "(str('a') >> str('ignore') >> str('b')) (no .as(...))" do
      it "should just flatten the result" do
        (str('a') >> str('ignore') >> str('b')).
          parse('aignoreb').should == 'aignoreb'
      end 
    end
    context "str('a').as(:a) >> str('b').as(:a)" do
      attr_reader :parslet
      before(:each) do
        @parslet = str('a').as(:a) >> str('b').as(:a)
      end
      
      it "should issue a warning that a key is being overwritten in merge" do
        flexmock(parslet).
          should_receive(:warn).once
        parslet.parse('ab').should == { :a => 'b' }
      end
      it "should return :a => 'b'" do
        parslet.parse('ab').should == { :a => 'b' }
      end  
    end
    context "str('a').maybe" do
      it "should return something in merge, even though it is nil" 
    end
  end

  describe "combinations thereof (regression)" do
    sucess =[
      [(str('a').repeat >> str('b').repeat), 'aaabbb'] 
    ].each do |(parslet, input)|
      describe "#{parslet.inspect} applied to #{input.inspect}" do
        it "should parse successfully" do
          parslet.parse(input)
        end
      end 
    end
  end
end