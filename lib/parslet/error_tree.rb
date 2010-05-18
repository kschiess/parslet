
# A tree structure that contains parse error messages. This can be used to
# give the user a detailed report on what went wrong during a parse. 
#
class Parslet::ErrorTree
  # The parslet that caused the error stored here. 
  attr_reader :parslet
  # All errors that were encountered when parsing part of this +parslet+. 
  attr_reader :children
    
  def initialize(parslet, *children)
    @parslet = parslet
    @children = children.compact
  end
  
  def nodes
    1 + children.inject(0) { |sum, node| sum + node.nodes }
  end
  
  def cause
    parslet.cause
  end
  alias :to_s :cause
  
  # Returns an ascii tree representation of the causes of this node and its
  # children. 
  #
  def ascii_tree
    StringIO.new.tap { |io| 
      recursive_ascii_tree(self, io, [true]) }.
      string
  end
private
  def recursive_ascii_tree(node, stream, curved)
    append_prefix(stream, curved)
    stream.puts node
    
    node.children.each do |child|
      last_child = (node.children.last == child)

      recursive_ascii_tree(child, stream, curved + [last_child])
    end
  end
  def append_prefix(stream, curved)
    curved[0..-2].each do |c|
      stream.print c ? "   " : "|- "
    end
    stream.print curved.last ? "`- " : "|- "
  end
end
