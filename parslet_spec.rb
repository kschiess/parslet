require 'parslet'

describe Parslet do
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
end