# A sequence of parslets, matched from left to right. Denoted by '>>'
#
# Example: 
#
#   str('a') >> str('b')  # matches 'a', then 'b'
#
class Parslet::Atoms::Sequence < Parslet::Atoms::Base
  attr_reader :parslets
  def initialize(*parslets)
    super()

    @parslets = parslets
    @error_msgs = {
      :failed  => "Failed to match sequence (#{self.inspect})"
    }
  end
  
  def >>(parslet) # :nodoc:
    self.class.new(* @parslets+[parslet])
  end
  
  def try(source, context) # :nodoc:
    success([:sequence]+parslets.map { |p| 
      # Save each parslet as potentially offending (raising an error). 
      @offending_parslet = p

      value = p.apply(source, context) 

      return error(source, @error_msgs[:failed]) if value.error?

      value.result
    })
  end
      
  precedence SEQUENCE
  def to_s_inner(prec) # :nodoc:
    parslets.map { |p| p.to_s(prec) }.join(' ')
  end

  def error_tree # :nodoc:
    Parslet::ErrorTree.new(self).tap { |t|
      t.children << @offending_parslet.error_tree if @offending_parslet }
  end
end
