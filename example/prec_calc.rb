
# A demonstration of the new precedence climbing infix expression parser. 

$:.unshift File.dirname(__FILE__) + "/../lib"

require 'rspec'
require 'parslet'
require 'parslet/rig/rspec'

class InfixExpressionParser < Parslet::Parser
  root :expression

  rule(:space) { match['\s'] }

  def cts atom
    atom >> space.repeat
  end
  def infix *args
    Infix.new(*args)
  end

  rule(:mul_op) { match['*/'] }
  rule(:add_op) { match['+-'] }
  rule(:digit) { match['0-9'] }
  rule(:integer) { cts digit.repeat(1) }

  rule(:expression) { infix_expression(integer, 
    [mul_op, 2, :left], 
    [add_op, 1, :right]) }
end

expression = (ARGV.empty? ? '1+2*2+3' : ARGV.join)
p InfixExpressionParser.new.parse(expression)