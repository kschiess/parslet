require 'parslet'
include Parslet

# Constructs a parser using a Parser Expression Grammar 
parser =  str('"') >> 
          (
            str('\\') >> any |
            str('"').absnt? >> any
          ).repeat.as(:string) >> 
          str('"')

result = parser.parse %Q("this is a valid string") 
result # => {:string=>"this is a valid string"@1} 
