$:.unshift '/Users/kaspar/git_work/own/rooc/ext/parslet/lib' # REMOVE ME
require 'parslet'

# Remove this later on!
class Parslet::Parser
  include Parslet
end

class Mini < Parslet::Parser
  root :integer
  rule(:integer) { match('[0-9]').repeat(1) }
  
  rule(:space)  { match('\s').repeat(1) }
  rule(:space?) { space.maybe }
end

p Mini.new.parse("132432")