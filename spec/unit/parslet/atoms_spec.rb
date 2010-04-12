require 'spec_helper'

require 'parslet'

describe Parslet do
  def not_parse
    raise_error(Parslet::Atoms::ParseFailed)
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
      }.should raise_error(Parslet::Atoms::ParseFailed)
    end 
    it "should print as [abc]" do
      parslet.inspect.should == "[abc]"
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
      }.should raise_error(Parslet::Atoms::ParseFailed)
    end 
    it "should succeed on 'aaa'" do
      parslet.parse('aaa')
    end 
    it "should succeed on many 'a'" do
      parslet.parse('a'*100)
    end 
    it "should inspect as [a]{3, }" do
      parslet.inspect.should == "[a]{3, }"
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
      }.should raise_error(Parslet::Atoms::ParseFailed)
    end
    it "should inspect as 'foo'" do
      parslet.inspect.should == "'foo'"
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
    it "should inspect as 'foo'?" do
      parslet.inspect.should == "'foo'?"
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
      }.should raise_error(Parslet::Atoms::ParseFailed)
    end
    it "should return self for chaining" do
      (parslet >> str('baz')).should == parslet
    end 
    it "should inspect as ('foo' 'bar')" do
      parslet.inspect.should == "'foo' 'bar'"
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
      }.should raise_error(Parslet::Atoms::ParseFailed)
    end   
    it "should return self for chaining" do
      (parslet / str('baz')).should == parslet
    end 
    it "should inspect as ('foo' / 'bar')" do
      parslet.inspect.should == "'foo' / 'bar'"
    end 
  end
  describe "str('foo').prsnt? (positive lookahead)" do
    attr_reader :parslet
    before(:each) do
      @parslet = str('foo').prsnt?
    end
    
    it "should inspect as &'foo'" do
      parslet.inspect.should == "&'foo'"
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
    
    it "should inspect as !'foo'" do
      parslet.inspect.should == "!'foo'"
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
  describe "non greedy matcher combined with greedy matcher (possible loop)" do
    attr_reader :parslet
    before(:each) do
      # repeat will always succeed, since it has a minimum of 0. It will not
      # modify input position in that case. absnt? will, depending on
      # implementation, match as much as possible and call its inner element
      # again. This leads to an infinite loop. This example tests for the 
      # absence of that loop. 
      @parslet = str('foo').repeat.maybe
    end
    
    it "should not loop infinitly" do
      begin 
        timeout 1 do
          parslet.parse('bar')
        end
      rescue Parslet::Atoms::ParseFailed
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
  describe "named entity entity('foo') { str('bar') }" do
    attr_reader :parslet
    before(:each) do
      @parslet = named('foo') { str('bar') }
    end
    
    it "should parse 'bar'" do
      parslet.parse('bar')
    end 
    it "should inspect as NAME" do
      parslet.inspect.should == "FOO"
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
          parse('aignoreb').should == 
          {
            :a => 'a', 
            :b => 'b'
          }
      end
    end
    
    context "(str('a') >> str('ignore') >> str('b')) (no .as(...))" do
      it "should return an empty subtree" do
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
        flexmock(parslet).
          should_receive(:warn)
          
        parslet.parse('ab').should == { :a => 'b' }
      end  
    end
    context "str('a').absnt?" do
      it "should return something in merge, even though it is nil" do
        (str('a').absnt? >> str('b').as(:b)).
          parse('b').should == {:b => 'b'}
      end
    end
    context "str('a').as(:a).repeat" do
      it "should return an array of subtrees" do
        str('a').as(:a).repeat.
          parse('aa').should == [{:a=>'a'}, {:a=>'a'}]
      end 
    end
  end
  describe "<- #flatten(val)" do
    def call(val)
      dummy = str('a')
      flexmock(dummy, :warn => nil)
      dummy.flatten(val)
    end
    
    [
      # In absence of named subtrees: ----------------------------------------
      # Sequence or Repetition
      [ [:sequence, 'a', 'b'], 'ab' ], 
      [ [:repetition, 'a', 'a'], 'aa' ],
            
      # Nested inside another node
      [ [:sequence, [:sequence, 'a', 'b']], 'ab' ],
      # Combined with lookahead (nil)
      [ [:sequence, nil, 'a'], 'a' ],
                  
      # Including named subtrees ---------------------------------------------
      # Atom: A named subtree
      [ {:a=>'a'}, {:a=>'a'} ],
      # Composition of subtrees
      [ [:sequence, {:a=>'a'},{:b=>'b'}], {:a=>'a',:b=>'b'} ],
      # Repetition of subtrees is handled elsewhere. (See Repetition)
      
      # Some random samples --------------------------------------------------
      [ [:sequence, {:a => :b, :b => :c}], {:a=>:b, :b=>:c} ], 
      [ [:sequence, {:a => :b}, 'a', {:c=>:d}], {:a => :b, :c=>:d} ], 
      [ [:repetition, {:a => :b}, 'a', {:c=>:d}], [{:a => :b}, {:c=>:d}] ], 
      [ [:sequence, {:a => :b}, {:a=>:d}], {:a => :d} ], 
      [ [:sequence, {:a=>:b}, [:sequence, [:sequence, "\n", nil]]], {:a=>:b} ], 
      [ [:sequence, nil, " "], ' ' ], 
    ].each do |input, output|
      it "should transform #{input.inspect} to #{output.inspect}" do
        call(input).should == output
      end
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

    inspection=[
      [str('a'),                              "'a'"                 ], 
      [(str('a') / str('b')).maybe,           "('a' / 'b')?"        ], 
      [(named('foo') {} / named('bar') {}),   "FOO / BAR"           ], 
      [(str('a') >> str('b')).maybe,          "('a' 'b')?"          ], 
      [str('a').maybe.maybe,                  "'a'??"               ], 
      [(str('a')>>str('b')).maybe.maybe,      "('a' 'b')??"         ], 
      [(str('a') >> (str('b') / str('c'))),   "'a' ('b' / 'c')"], 
      
      [str('a') >> str('b').repeat,           "'a' 'b'{0, }"        ], 
      [(str('a')>>str('b')).repeat,           "('a' 'b'){0, }"      ]  
    ].each do |(parslet, inspect_output)|
      context "regression for #{parslet.inspect}" do
        it "should inspect correctly as #{inspect_output}" do
          parslet.inspect.should == inspect_output
        end 
      end
    end
  end
end