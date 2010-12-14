require 'parslet'
include Parslet

tree = {:left => {:int => '1'}, 
        :op   => '+', 
        :right => {:int => '2'}}
        
class Trans < Parslet::Transform
  rule(:int => simple(:x)) { Integer(x) }
  rule(:op => '+', :left => simple(:l), :right => simple(:r)) { l + r }
end
p Trans.new.apply(tree)     # => 3
