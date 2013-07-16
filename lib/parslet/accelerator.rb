module Parslet::Accelerator

  class Expression
    attr_reader :type
    attr_reader :args

    def initialize(type, *args)
      @type = type
      @args = args
    end

    def >> other_expr
      if type == :seq
        @args << other_expr
      else
        Expression.new(:seq, self, other_expr)
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