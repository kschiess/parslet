$:.unshift '../lib'

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
require 'rexp_matcher'
RExpMatcher.new(tree).
  match({:string => :_x}) { |d| puts "String contents: #{d[:x]}" }
