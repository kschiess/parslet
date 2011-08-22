
# Alternative during matching. Contains a list of parslets that is tried each
# one in turn. Only fails if all alternatives fail. 
#
# Example: 
# 
#   str('a') | str('b')   # matches either 'a' or 'b'
#
class Parslet::Atoms::Alternative < Parslet::Atoms::Base
  attr_reader :alternatives
  
  # Constructs an Alternative instance using all given parslets in the order
  # given. This is what happens if you call '|' on existing parslets, like 
  # this: 
  #
  #   str('a') | str('b')
  #
  def initialize(*alternatives)
    super()
    
    @alternatives = alternatives
    @error_msg = "Expected one of #{alternatives.inspect}."
  end

  #---
  # Don't construct a hanging tree of Alternative parslets, instead store them
  # all here. This reduces the number of objects created.
  #+++
  def |(parslet) # :nodoc:
    self.class.new(*@alternatives + [parslet])
  end
  
  def try(source, context) # :nodoc:
    alternatives.each { |a|
      value = a.apply(source, context)
      return value unless value.error?
    }
    # If we reach this point, all alternatives have failed. 
    error(source, @error_msg)
  end

  precedence ALTERNATE
  def to_s_inner(prec) # :nodoc:
    alternatives.map { |a| a.to_s(prec) }.join(' / ')
  end

  def error_tree # :nodoc:
    Parslet::ErrorTree.new(self, *alternatives.
      map { |child| child.error_tree })
  end
end
