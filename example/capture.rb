
# This example demonstrates how pieces of input can be captured and matched
# against later on. Without this, you cannot match here-documents and other
# self-dependent grammars. 

$:.unshift File.dirname(__FILE__) + "/../lib"
require 'parslet'
require 'parslet/convenience'
require 'pp'



class CapturingParser < Parslet::Parser
  root :document
  
  rule(:document) { scope { doc_start >> text >> doc_end } }
  rule(:doc_start) { str('<') >> marker >> newline }
  rule(:text) { (document.as(:doc) | text_line.as(:line)).repeat(1) }
  rule(:text_line) { captured_marker.absent? >> any >> 
    (newline.absent? >> any).repeat >> newline }
  rule(:doc_end) { captured_marker }
  
  rule(:marker) { match['A-Z'].repeat(1).capture(:marker) }
  rule(:newline) { match["\n"] }
  rule(:captured_marker) { 
    dynamic { |source, context|
      str(context.captures[:marker])
    }
  }
end

parser = CapturingParser.new
pp parser.parse_with_debug %Q(<CAPTURE
Text1
<FOOBAR
Text3
Text4
FOOBAR
Text2
CAPTURE)

