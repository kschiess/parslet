
require 'parslet/atoms/visitor'

module Parslet::Accelerator
  class Apply
    def initialize(engine, expr)
      @engine = engine
      @expr = expr
    end

    def visit_parser(root)
      false
    end
    def visit_entity(name, block)
      false
    end
    def visit_named(name, atom)
      false
    end
    def visit_repetition(tag, min, max, atom)
      false
    end
    def visit_alternative(alternatives)
      false
    end
    def visit_sequence(sequence)
      match(:seq) do |*expressions|
        return false if sequence.size != expressions.size

        sequence.zip(expressions).all? do |atom, expr|
          @engine.match(atom, expr)
        end
      end
    end
    def visit_lookahead(positive, atom)
      false
    end
    def visit_re(regexp)
      match(:re) do |variable|
        @engine.try_bind(variable, regexp)
      end
    end
    def visit_str(str)
      match(:str) do |variable|
        @engine.try_bind(variable, str)
      end
    end

    def match(type_tag)
      expr_tag = @expr.type
      if expr_tag == type_tag
        yield *@expr.args
      end
    end
  end

  class Engine
    attr_reader :bindings

    def initialize 
      @bindings = {}
    end

    def match(atom, expr)
      atom.accept(
        Apply.new(self, expr))
    end

    def try_bind(variable, value)
      if @bindings.has_key? variable
        return value == @bindings[variable]
      else
        @bindings[variable] = value
        return true
      end
    end
  end
end