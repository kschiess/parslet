require 'parslet'
include Parslet

tree = {:left => {:int => '1'}, 
        :op   => '+', 
        :right => {:int => '2'}}
        
class Trans < Parslet::Transform
  rule(:int => simple(:x)) { Integer(x) }
end
p Trans.new.apply(tree)     # => {:op=>"+", :right=>2, :left=>1}
