require 'parslet'

describe Parslet do
  def not_parse
    raise_error(Parslet::Matchers::ParseFailed)
  end
  
  include Parslet
  describe "match('[abc]')" do
    attr_reader :parslet
    before(:each) do
      @parslet = match('[abc]')
    end
    
    it "should parse {a,b,c}" do
      parslet.apply('a')
      parslet.apply('b')
      parslet.apply('c')
    end 
    it "should not parse d" do
      lambda {
        parslet.apply('d')
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
        parslet.apply('aa')
      }.should raise_error(Parslet::Matchers::ParseFailed)
    end 
    it "should succeed on 'aaa'" do
      parslet.apply('aaa')
    end 
    it "should succeed on many 'a'" do
      parslet.apply('a'*100)
    end 
  end
  describe "str('foo')" do
    attr_reader :parslet
    before(:each) do
      @parslet = str('foo')
    end
    
    it "should parse 'foo'" do
      parslet.apply('foo')
    end
    it "should not parse 'bar'"  do
      lambda {
        parslet.apply('bar')
      }.should raise_error(Parslet::Matchers::ParseFailed)
    end
  end
  describe "str('foo').maybe" do
    attr_reader :parslet
    before(:each) do
      @parslet = str('foo').maybe
    end

    it "should parse a foo" do
      parslet.apply('foo')
    end
    it "should leave pos untouched if there is no foo" do
      io = StringIO.new('bar')
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
      parslet.apply('foobar')
    end
    it "should not parse 'foobaz'" do
      lambda {
        parslet.apply('foobaz')
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
      parslet.apply('foo')
    end
    it "should accept 'bar'" do
      parslet.apply('bar')
    end
    it "should not accept 'baz'" do
      lambda {
        parslet.apply('baz')
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
        parslet.apply('foo')
      end
      it "should not change input position" do
        io = StringIO.new('foo')
        parslet.apply(io)
        io.pos.should == 0
      end
    end
    context "when fed 'bar'" do
      it "should not parse" do
        lambda { parslet.apply('bar') }.should not_parse
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
        parslet.apply('bar')
      end
      it "should not change input position" do
        io = StringIO.new('bar')
        parslet.apply(io)
        io.pos.should == 0
      end
    end
    context "when fed 'foo'" do
      it "should not parse" do
        lambda { parslet.apply('foo') }.should not_parse
      end
    end
  end
  describe "any" do
    attr_reader :parslet
    before(:each) do
      @parslet = any
    end
    
    it "should match" do
      parslet.apply('.')
    end 
    it "should consume one char" do
      io = StringIO.new('foo')
      parslet.apply(io)
      io.pos.should == 1
    end 
  end
end