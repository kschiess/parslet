require 'parslet'

class Mini < Parslet::Parser
  # Single character rules
  rule(:lparen)     { str('(') >> space? }
  rule(:rparen)     { str(')') >> space? }
  rule(:comma)      { str(',') >> space? }

  rule(:space)      { match('\s').repeat(1) }
  rule(:space?)     { space.maybe }

  # Things
  rule(:integer)    { match('[0-9]').repeat(1) >> space? }
  rule(:identifier) { match['a-z'].repeat(1) }
  rule(:operator)   { match('[+]') >> space? }
  
  # Grammar parts
  rule(:sum)        { integer.as(:l) >> operator.as(:o) >> expression.as(:r) }
  rule(:arglist)    { expression.as(:a) >> (comma >> expression.as(:a)).repeat }
  rule(:funcall)    { identifier.as(:f) >> lparen >> arglist >> rparen }
  
  rule(:expression) { funcall | sum | integer }
  root :expression
end

def parse(str)
  mini = Mini.new
  print "Parsing #{str}: "
  
  p mini.parse(str)
rescue Parslet::ParseFailed => error
  puts error, mini.root.error_tree
end

parse "1 + 2 + 3"
parse "puts(1 + 2 + 3)"
parse "puts(1 + 2 + 3, 45)"