module Parslet
  # An internal class that allows delaying the construction of error messages
  # (as strings) until we really need to print them. 
  #
  class Cause < Struct.new(:message, :source, :pos, :children) # :nodoc: 
    # Appends 'at line ... char ...' to the string given. Use +pos+ to
    # override the position of the +source+. This method returns an object
    # that can be turned into a string using #to_s.
    #
    def self.format(source, pos, str)
      self.new(str, source, pos)
    end
    
    def to_s
      line, column = source.line_and_column(pos)
      # Allow message to be a list of objects. Join them here, since we now
      # really need it. 
      Array(message).map { |o| 
        o.respond_to?(:to_slice) ? 
          o.str.inspect : 
          o.to_s }.join + " at line #{line} char #{column}."
    end
    
    # Signals to the outside that the parse has failed. Use this in
    # conjunction with .format for nice error messages. 
    #
    def raise(exception_klass=Parslet::ParseFailed)
      exception = exception_klass.new(self.to_s, self)
      Kernel.raise exception
    end

    # Returns an ascii tree representation of the causes of this node and its
    # children. 
    #
    def ascii_tree
      StringIO.new.tap { |io| 
        recursive_ascii_tree(self, io, [true]) }.
        string
    end

  private
    def recursive_ascii_tree(node, stream, curved) # :nodoc:
      append_prefix(stream, curved)
      stream.puts node.to_s

      node.children.each do |child|
        last_child = (node.children.last == child)

        recursive_ascii_tree(child, stream, curved + [last_child])
      end
    end
    def append_prefix(stream, curved) # :nodoc:
      return if curved.size < 2
      curved[1..-2].each do |c|
        stream.print c ? "   " : "|  "
      end
      stream.print curved.last ? "`- " : "|- "
    end
  end
end