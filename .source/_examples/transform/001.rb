require 'parslet'
include Parslet

class MyTransform < Parslet::Transform
  rule('a') { 'b' }
end
MyTransform.new.apply('a') # => 'b'