
$:.unshift File.dirname(__FILE__) + "/../lib"
require 'parslet'

class ErbParser < Parslet::Parser
  rule(:ruby) { str('<%') >> (str('%>').absnt? >> any).repeat >> str('%>') }
  rule(:html) { (str('<%').absnt? >> any).repeat(1) }
  rule(:html_with_ruby) { (html.as(:html) | ruby.as(:ruby)).repeat }
  root(:html_with_ruby)
end

p ErbParser.new.parse <<ERB
The value of x is: <%= x %>
ERB
