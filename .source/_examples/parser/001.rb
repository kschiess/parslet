require 'parslet'
include Parslet

[
  "Normal strings just map to strings", nil, 
  "str('a').repeat", 'aaa',
  
  "Arrays capture repetition of non-strings", nil,
  "str('a').repeat.as(:b)", 'aaa',
  "str('a').as(:b).repeat", 'aaa',
  
  "Subtrees get merged - unlabeled strings discarded", nil,
  "str('a').as(:a) >> str('b').as(:b)", 'ab',
  "str('a') >> str('b').as(:b) >> str('c')", 'abc',

  "\#maybe will return nil, not the empty array", nil,
  "str('a').maybe.as(:a)", 'a', 
  "str('a').maybe.as(:a)", '', 
].each_slice(2) do |parslet, input|
  if input
    printf("%-40s %-40s\n", parslet, eval(parslet).parse(input).inspect)
  else
    puts
    printf("# %s\n", parslet)
  end
end
