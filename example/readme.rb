# The example from the readme. With this, I am making sure that the readme 
# 'works'. Is this too messy?

$:.unshift '../lib'

require 'pp'
require 'parslet'
include Parslet

require 'parslet'
include Parslet

# Constructs a parser using a Parser Expression Grammar like DSL: 
parser =  str('"') >> 
          (
            str('\\') >> any |
            str('"').absnt? >> any
          ).repeat.as(:string) >> 
          str('"')
  
# Parse the string and capture parts of the interpretation (:string above)        
tree = parser.parse(%Q{
  "This is a \\"String\\" in which you can escape stuff"
}.strip)

tree # => {:string=>"This is a \\\"String\\\" in which you can escape stuff"}

# Here's how you can grab results from that tree:

# 1)
transform = Parslet::Transform.new do
  rule(:string => simple(:x)) { 
    puts "String contents (method 2): #{x}" }
end
transform.apply(tree)

