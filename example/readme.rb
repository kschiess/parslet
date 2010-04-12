$:.unshift '../lib'

require 'pp'
require 'parslet'
include Parslet

# Constructs a parser using a Parser Expression Grammar like DSL: 
parser =  str('"') >> 
          (
            (str('\\') >> any) /
            (str('"').absnt? >> any)
          ).repeat.as(:string) >> 
          str('"')
    
# Parse the string and capture parts of the interpretation (:string above)        
tree = parser.parse(%Q{
  "This is a \\"String\\" in which you can escape stuff"
}.strip)

tree # => {:string=>"This is a \\\"String\\\" in which you can escape stuff"}

# Here's how you can grab results from that tree: 
Pattern.new(:string => :_x).each_match(tree) do |dictionary|
  puts "String contents: #{dictionary[:x]}"
end
  
# Here's how to transform that tree into something else ----------------------

# Defines the classes of our new Syntax Tree
class StringLiteral < Struct.new(:text); end

# Defines a set of transformation rules on tree leafes
transform = Transform.new
transform.rule(:string => :_x) { |d| StringLiteral.new(d[:x]) }

# Transforms the tree
transform.apply(tree) 
# => #<struct StringLiteral text="This is a \\\"String\\\" ... escape stuff">