$:.unshift File.dirname(__FILE__) + "/../lib"
require 'parslet'

class ErbParser < Parslet::Parser
  rule(:code) { (str('%>').absnt? >> any).repeat.as(:code) }
  
  rule(:expression) { (str('=') >> code).as(:expression) }
  rule(:comment) { (str('#') >> code).as(:comment) }
  rule(:erb) { expression | comment | code }
  
  rule(:erb_with_tags) { str('<%') >> erb >> str('%>') }
  rule(:text) { (str('<%').absnt? >> any).repeat(1) }
  
  rule(:text_with_ruby) { (text.as(:text) | erb_with_tags).repeat }
  root(:text_with_ruby)
end

p ErbParser.new.parse "The value of x is <%= x %>."
p ErbParser.new.parse "<% 1 + 2 %>"
p ErbParser.new.parse "<%# commented %>"