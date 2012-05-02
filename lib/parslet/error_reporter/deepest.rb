module Parslet
  module ErrorReporter
    # TODO describe
    class Deepest
      def initialize
        @deepest_cause = nil
      end
      
      # Produces an error cause that combines the message at the current level
      # with the errors that happened at a level below (children).
      #
      # @param source [Source] Source that we're using for this parse. (line 
      #   number information...)
      # @param message [String, Array] Error message at this level.
      # @param children [Array] A list of errors from a deeper level (or nil).
      # @return [Cause] An error tree combining children with message.
      #
      def err(source, message, children=nil)
        position = source.pos
        cause = Cause.format(source, position, message, children)
        return deepest(cause)
      end

      # Produces an error cause that combines the message at the current level
      # with the errors that happened at a level below (children).
      #
      # @param source [Source] Source that we're using for this parse. (line 
      #   number information...)
      # @param message [String, Array] Error message at this level.
      # @param pos [Fixnum] The real position of the error.
      # @param children [Array] A list of errors from a deeper level (or nil).
      # @return [Cause] An error tree combining children with message.
      #
      def err_at(source, message, pos, children=nil)
        position = pos
        cause = Cause.format(source, position, message, children)
        return deepest(cause)
      end
      
    private
      # Checks to see if the lineage of the cause given includes a cause with
      # an error position deeper than the current deepest cause stored. If
      # yes, it passes the cause through to the caller. If no, it returns the
      # current deepest error that was saved as a reference.
      #
      def deepest(cause)
        rank, leaf = deepest_child(cause)
        
        if !@deepest_cause || leaf.pos >= @deepest_cause.pos
          # This error reaches deeper into the input, save it as reference.
          @deepest_cause = leaf
          return cause
        end
        
        return @deepest_cause
      end
      
      # Returns the leaf from a given error tree with the biggest rank. 
      #
      def deepest_child(cause, rank=0)
        max_child = cause
        max_rank  = rank
        
        if cause.children && !cause.children.empty?
          cause.children.each do |child|
            c_rank, c_cause = deepest_child(child, rank+1)
            
            if c_rank > max_rank
              max_rank = c_rank
              max_child = c_cause
            end
          end
        end
        
        return max_rank, max_child
      end
    end
  end
end