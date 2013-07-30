
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
      match(:alt) do |*expressions|
        return false if alternatives.size != expressions.size

        alternatives.zip(expressions).all? do |atom, expr|
          @engine.match(atom, expr)
        end
      end
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
      match(:re) do |*bind_conditions|
        bind_conditions.all? { |bind_cond| 
          @engine.try_bind(bind_cond, regexp) }
      end
    end
    def visit_str(str)
      match(:str) do |*bind_conditions|
        bind_conditions.all? { |bind_cond| 
          @engine.try_bind(bind_cond, str) }
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
      if bound? variable
        return value == lookup(variable)
      else
        case variable
          when Symbol
            bind(variable, value)
        else
          # This does not look like a variable - let's try matching it against
          # the value: 
          variable === value
        end    
      end
    end
    def bound? var
      @bindings.has_key? var
    end
    def lookup var
      @bindings[var]
    end
    def bind var, val
      @bindings[var] = val
    end
  end
end