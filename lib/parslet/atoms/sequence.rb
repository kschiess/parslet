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
  
  def try(source, context, consume_all)
    succ([:sequence]+parslets.map.each_with_index { |p, idx| 
      child_consume_all = consume_all && (idx == parslets.size-1)
      success, value = p.apply(source, context, child_consume_all) 

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
