
# Alternative during matching. Contains a list of parslets that is tried each
# one in turn. Only fails if all alternatives fail. 
#
# Example: 
# 
#   str('a') | str('b')   # matches either 'a' or 'b'
#
class Parslet::Atoms::Alternative < Parslet::Atoms::Base
  attr_reader :alternatives
  def initialize(*alternatives)
    @alternatives = alternatives
  end
  
  def |(parslet)
    @alternatives << parslet
    self
  end
  
  def try(io)
    alternatives.each { |a|
      begin
        return a.apply(io)
      rescue Parslet::ParseFailed => ex
      end
    }
    # If we reach this point, all alternatives have failed. 
    error(io, "Expected one of #{alternatives.inspect}.")
  end

  precedence ALTERNATE
  def to_s_inner(prec)
    alternatives.map { |a| a.to_s(prec) }.join(' | ')
  end

  def error_tree
    Parslet::ErrorTree.new(self, *alternatives.
      map { |child| child.error_tree })
  end
end
