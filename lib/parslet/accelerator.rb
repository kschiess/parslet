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
  def str variable
    Expression.new(:str, variable)
  end

  def re variable
    Expression.new(:re, variable)
  end

  def match atom, expr
    engine = Engine.new

    return engine.bindings if engine.match(atom, expr)
    return false
  end
end

require 'parslet/accelerator/engine'