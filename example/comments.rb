# A small example on how to parse common types of comments. The example
# started out with parser code from Stephen Waits. 

$:.unshift '../lib'

require 'pp'
require 'parslet'
require 'parslet/convenience'

class ALanguage < Parslet::Parser
  root(:expressions)
  
  rule(:expressions) { (line >> eol).repeat(1) | line }
  rule(:line) { space? >> an_expression.as(:exp).repeat }
  rule(:an_expression) { str('a').as(:a) >> space? }
  
  rule(:eol) { space? >> match["\n\r"].repeat(1) >> space? }
  
  rule(:space?) { space.repeat }
  rule(:space) { multiline_comment.as(:multi) | line_comment.as(:line) | str(' ') }

  rule(:line_comment) { str('//') >> (match["\n\r"].absnt? >> any).repeat }
  rule(:multiline_comment) { str('/*') >> (str('*/').absnt? >> any).repeat >> str('*/') }
end

code = %q(
  a
  // line comment
  a a a // line comment
  a /* inline comment */ a 
  /* multiline
  comment */
)

pp ALanguage.new.parse_with_debug(code)


