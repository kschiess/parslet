# An example that explores left recursion. This ruthlessly reopens parslets 
# internals and should not be used in production. I am however working on 
# something like this that will see a real release someday. 

$:.unshift File.dirname(__FILE__) + "/../lib"

require 'pp'
require 'parslet'
require 'parslet/convenience'

class SimpleLang < Parslet::Parser
  # root(:b)
  # 
  # # either any number of 'a's or a 'b'
  # rule(:b) { c | e }
  # rule(:c) { d }
  # rule(:d) { b | str('a') }
  # rule(:e) { str('b') }
  
  root(:exp)
  rule(:exp) { foo >> str('-') >> num | foo >> str('+') >> num | num }
  rule(:foo) { exp }
  rule(:num) { match['0-9'].repeat(1) }
end

# p SimpleLang.new.parse_with_debug('aaaa')
# p SimpleLang.new.parse_with_debug('a')
# p SimpleLang.new.parse_with_debug('b')

p SimpleLang.new.parse_with_debug('1+2')