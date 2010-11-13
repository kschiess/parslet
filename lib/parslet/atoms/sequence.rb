# A sequence of parslets, matched from left to right. Denoted by '>>'
#
class Parslet::Atoms::Sequence < Parslet::Atoms::Base
  attr_reader :parslets
  def initialize(*parslets)
    @parslets = parslets
  end
  
  def >>(parslet)
    @parslets << parslet
    self
  end
  
  def try(io)
    [:sequence]+parslets.map { |p| 
      # Save each parslet as potentially offending (raising an error). 
      @offending_parslet = p
      p.apply(io) 
    }
  rescue Parslet::ParseFailed
    error(io, "Failed to match sequence (#{self.inspect})")
  end
      
  precedence SEQUENCE
  def to_s_inner(prec)
    parslets.map { |p| p.to_s(prec) }.join(' ')
  end

  def error_tree
    Parslet::ErrorTree.new(self).tap { |t|
      t.children << @offending_parslet.error_tree if @offending_parslet }
  end
end
