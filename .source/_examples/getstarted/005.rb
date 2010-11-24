require 'parslet'


class SimpleTransform < Parslet::Transform
  rule(funcall: 'puts', arglist: sequence(:args)) {
    "puts(#{args.inspect})"
  }
end

tree = {funcall: 'puts', arglist: [1,2,3]}
SimpleTransform.new.apply(tree) # => "puts([1, 2, 3])"