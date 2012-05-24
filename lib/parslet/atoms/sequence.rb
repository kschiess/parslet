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
  
  def >>(parslet)
    self.class.new(* @parslets+[parslet])
  end
  
  def try(source, context)
    succ([:sequence]+parslets.map { |p| 
      success, value = p.apply(source, context) 

      unless success
        return context.err(self, source, @error_msgs[:failed], [value]) 
      end
      
      value
    })
  end
      
  precedence SEQUENCE
  def to_s_inner(prec)
    parslets.map { |p| p.to_s(prec) }.join(' ')
  end
end
