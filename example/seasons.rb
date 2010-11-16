
$:.unshift '../lib/'
require 'parslet'
require 'pp'

tree = {:bud => {:stem => []}}

class ComeSpring < Parslet::Transform
  rule(:stem => sequence(:branches)) {
    {:stem => (branches + [{:branch => :leaf}])}
  }
end
class ComeSummer < Parslet::Transform
  rule(:stem => subtree(:branches)) {
    new_branches = branches.map { |b| {:branch => [:leaf, :flower]} }
    {:stem => new_branches}
  }
end
class ComeFall < Parslet::Transform
  rule(:branch => sequence(:x)) {
    x.each { |e| puts "Fruit!" if e==:flower }
    x.each { |e| puts "Faling Leaves!" if e==:leaf }
    {:branch => []}
  }
end
class ComeWinter < Parslet::Transform
  rule(:stem => subtree(:x)) {
    {:stem => []}
  }
end

def do_seasons(tree)
  ['spring', 'summer', 'fall', 'winter'].each do |season|
    klass = Kernel.const_get "Come"+season.capitalize
    tree = klass.new.apply(tree)
    p "And when #{season} comes"
    pp tree
  end
  tree
end

# What marvel of life!
tree = do_seasons(tree)
tree = do_seasons(tree)


