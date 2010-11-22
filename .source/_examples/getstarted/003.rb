require 'parslet'
include Parslet

# Without structure: just strings.
str('ooo').parse('ooo')                           # => 'ooo'
str('o').repeat.parse('ooo')                      # => 'ooo'

# Added structure: .as(...)
str('ooo').as(:ex1).parse('ooo')                  # => {:ex1=>"ooo"}
str('o').as(:ex2a).repeat.as(:ex2b).parse('ooo')  # => {:ex2b=>[{:ex2a=>"o"}, {:ex2a=>"o"}, {:ex2a=>"o"}]}

# Discard behaviour
parser =  str('a').as(:a) >> str(' ').maybe >> 
          str('+').as(:o) >> str(' ').maybe >> 
          str('b').as(:b)
parser.parse('a + b') # => {:a=>"a", :o=>"+", :b=>"b"}
