require 'spec_helper'

require 'parslet/atoms/transform'

describe Parslet::Atoms::Transform do
  include Parslet
  
  class ModifyAll < Parslet::Atoms::Transform; end
  describe ModifyAll do
    subject { ModifyAll.new }
    def apply(grammar)
      subject.apply(grammar)
    end

    context "str" do
      class ModifyAll
        def visit_str(s)
          super(s.reverse)
        end
      end
      it "should reverse the string" do
        apply(str('foo')).should parse('oof')
      end 
    end
    context "sequence" do
      class ModifyAll
        def visit_sequence(seq)
          super(seq.reverse)
        end
      end
      it "should reverse sequences" do
        apply(str('a') >> str('b')).should parse('ba')
      end 
    end
    context "re" do
      class ModifyAll
        def visit_re(match)
          super(match.delete('a'))
        end
      end
      it "should not match a's" do
        apply(match['ab']).should_not parse('a')
        apply(match['ab']).should parse('b')
      end 
    end
    context "alternative" do
      class ModifyAll
        def visit_alternative(parslets)
          super(parslets.reverse)
        end
      end
      it "should reverse priorities" do
        apply(
          str('foobar').as(:whole) |
          str('foo').as(:foo) >> str('bar').as(:bar)
        ).should parse('foobar').as(:foo => 'foo', :bar => 'bar')
      end 
    end
    context "lookahead" do
      class ModifyAll
        def visit_lookahead(positive, parslet)
          super(!positive, parslet)
        end
      end
      it "should transform a positive lookahead into a negative lookahead" do
        apply(
          # The order of the sequence gets reversed as well...
          str('foo') >> str('foo').absnt?
        ).should parse('oof')
      end 
    end
    context "entity" do
      class ModifyAll
        def visit_entity(name, context, block)
          super(name, context, block)
        end
      end
      it "should lazily produce a transformed grammar" do
        block = proc { str('bar') }
        apply(
          Parslet::Atoms::Entity.new(:foo, self, block)
        ).should parse('rab')
      end 
    end
    context "repetition" do
      class ModifyAll
        def visit_repetition(min, max, parslet)
          super(min+1, max, parslet)
        end
      end
      it "should increase min by one" do
        apply(str('a').repeat(1)).should_not parse('a')
        apply(str('a').repeat(1)).should parse('aa')
      end 
    end
    context "named" do
      class ModifyAll
        def visit_named(name, parslet)
          super(:bar, parslet)
        end
      end
      it "should change name to :bar" do
        apply(str('a').as(:foo)).should parse('a').as(:bar => 'a')
      end 
    end
  end
  
end