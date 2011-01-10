
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
    @alternatives = alternatives
  end

  #---
  # Don't construct a hanging tree of Alternative parslets, instead store them
  # all here. This reduces the number of objects created.
  #+++
  def |(parslet) # :nodoc:
    @alternatives << parslet
    self
  end
  
  def try(io) # :nodoc:
    alternatives.each { |a|
      catch(:error) {
        return a.apply(io)
      }
    }
    # If we reach this point, all alternatives have failed. 
    error(io, "Expected one of #{alternatives.inspect}.")
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
