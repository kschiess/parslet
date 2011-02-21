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
          str('foo').absnt? >> str('foo')
        ).should parse('oof')
      end 
    end
  end
  
end