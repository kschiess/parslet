require 'parslet'

class Mini < Parslet::Parser
  rule(:integer)    { match('[0-9]').repeat(1) >> space? }
  
  rule(:space)      { match('\s').repeat(1) }
  rule(:space?)     { space.maybe }
  
  rule(:operator)   { match('[+]') >> space? }
  
  rule(:sum)        { integer >> operator >> expression }
  rule(:expression) { sum | integer }

  root :expression
end

def parse(str)
  mini = Mini.new
  print "Parsing #{str}: "
  
  p mini.parse(str)
rescue Parslet::ParseFailed => error
  puts error, mini.root.error_tree
end

parse "1 ++ 2"