require 'parslet'
include Parslet

str('foo').parse('foo')         # => 'foo'
match('[a-z]').parse('f')       # => 'f'

p (str('a') >> str('b').repeat(1).maybe).parse('ab')  
p (str('a') >> str('b').repeat(1).maybe).parse('a')  