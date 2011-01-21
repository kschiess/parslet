$:.unshift File.dirname(__FILE__) + "/../lib"
require 'parslet'

class ErbParser < Parslet::Parser
  rule(:ruby) { (str('%>').absnt? >> any).repeat.as(:ruby_code) }
  rule(:possible_ruby_expression) { ((str('=') >> ruby).as(:ruby_expression) | ruby) }
  rule(:erb_ruby) { str('<%') >> possible_ruby_expression >> str('%>') }
  rule(:text) { (str('<%').absnt? >> any).repeat(1) }
  rule(:text_with_ruby) { (text.as(:text) | erb_ruby).repeat }
  root(:text_with_ruby)
end

p ErbParser.new.parse "The value of x is <%= x %>."
p ErbParser.new.parse "<% 1 + 2 %>"