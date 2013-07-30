module Parslet::Accelerator

  class Expression
    attr_reader :type
    attr_reader :args

    def initialize(type, *args)
      @type = type
      @args = args
    end

    def >> other_expr
      join_or_new :seq, other_expr
    end

    def | other_expr
      join_or_new :alt, other_expr
    end

    def absent?
      Expression.new(:absent, self)
    end
    def present?
      Expression.new(:present, self)
    end

    def repeat min=0, max=nil
      Expression.new(:rep, min, max, self)
    end

    def join_or_new tag, other_expr
      if type == tag
        @args << other_expr
      else
        Expression.new(tag, self, other_expr)
      end
    end
  end

module_function 
  def str variable, *constraints
    Expression.new(:str, variable, *constraints)
  end

  def re variable, *constraints
    Expression.new(:re, variable, *constraints)
  end

  def match atom, expr
    engine = Engine.new

    return engine.bindings if engine.match(atom, expr)
  end
end

require 'parslet/accelerator/engine'