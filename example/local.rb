
$:.unshift File.dirname(__FILE__) + "/../lib"
require 'parslet'
include Parslet

a =  str('a').repeat >> str('aa')

# E1% E2
# 
# S = E2 | E1 S 

class Local <  Parslet::Atoms::Base
  def initialize(&block)
    @block = block
  end
  
  def try(source, context) # :nodoc:
    parslet.apply(source, context)
  end
  
  def parslet
    @parslet ||= @block[]
  end
  
  def to_s_inner(prec) # :nodoc:
    '{ ... }'
  end
end

def this(&block); return Local.new(&block) end
def epsilon; any.absnt? end 

# Traditional repetition will try as long as the pattern can be matched and 
# then give up. This is greedy and blind. 
a = str('a').as(:e) >> this { a }.as(:rec) | epsilon

# Here's a pattern match that is greedy and non-blind. The first pattern
# 'a'* will be tried as many times as possible, while still matching the 
# end pattern 'aa'.
b = str('aa').as(:e2) >> epsilon | str('a').as(:e1) >> this { b }.as(:rec)

p a.parse('aaaa')
p b
p b.parse('aaaa')
