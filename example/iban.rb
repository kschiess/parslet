# A small example on how to parse common types of comments. The example
# started out with parser code from Stephen Waits. 

$:.unshift File.dirname(__FILE__) + "/../lib"

require 'pp'
require 'parslet'
require 'parslet/convenience'

class ALanguage < Parslet::Parser
  root(:lines)
  
  rule(:lines) { line.repeat }
  rule(:line) { iban >> newline.maybe }
  rule(:newline) { str("\n") }
  
  rule(:iban) { match(/[A-Z]{2}\d\d( [A-Z\d]{4}){1,6}( [A-Z\d]{1,4})/i).as(:iban) }
end

valid = [
  'NO93 8601 1117 947',
  'nl91 abna 0417 1643 00',
  'MT84 MALT 0110 0001 2345 MTLC AST0 01S'
].join("\n")

invalid = [
  'NO93 8601 1117 947',
  'foobar'
].join("\n")

pp ALanguage.new.parse_with_debug(valid)
pp ALanguage.new.parse_with_debug(invalid)
