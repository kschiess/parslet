require 'parslet'
include Parslet

# Without structure: just strings.
str('ooo').parse('ooo')                           # => "ooo"@0
str('o').repeat.parse('ooo')                      # => "ooo"@0

# Added structure: .as(...)
str('ooo').as(:ex1).parse('ooo')                  # => {:ex1=>"ooo"@0}
str('o').as(:ex2a).repeat.as(:ex2b).parse('ooo')  # => {:ex2b=>[{:ex2a=>"o"@0}, {:ex2a=>"o"@1}, {:ex2a=>"o"@2}]}

# Discard behaviour
parser =  str('a').as(:a) >> str(' ').maybe >> 
          str('+').as(:o) >> str(' ').maybe >> 
          str('b').as(:b)
parser.parse('a + b') # => {:b=>"b"@4, :o=>"+"@2, :a=>"a"@0}
