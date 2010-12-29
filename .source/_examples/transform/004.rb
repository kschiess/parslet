require 'parslet'
include Parslet

y = 'way'
transform = Parslet::Transform.new do
  rule(:foo => simple(:x)) { x + y }
  rule(:bar => simple(:x)) { |d| d[:x] + y }
end

tree = { :bar => 'ex' }
p transform.apply(tree)     # => 3
