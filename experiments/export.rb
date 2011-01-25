
$:.unshift File.dirname(__FILE__) + "/../lib"
require 'parslet'

require 'parslet/export'

class FooParser < Parslet::Parser
  rule(:foo) { str('foo') }
  root(:foo)
end

puts FooParser.new.to_treetop
