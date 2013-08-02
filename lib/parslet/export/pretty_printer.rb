module Parslet
  class Parser
    # A helper class that formats Citrus and Treetop grammars as a string.
    #
    class PrettyPrinter
      attr_reader :visitor
      def initialize(visitor_klass)
        @visitor = visitor_klass.new(self)
      end

      # Pretty prints the given parslet using the visitor that has been
      # configured in initialize. Returns the string representation of the
      # Citrus or Treetop grammar.
      #
      def pretty_print(name, parslet)
        output = "grammar #{name}\n"

        output << rule('root', parslet)

        seen = Set.new
        loop do
          # @todo is constantly filled by the visitor (see #deferred). We
          # keep going until it is empty.
          break if @todo.empty?
          name, block = @todo.shift

          # Track what rules we've already seen. This breaks loops.
          next if seen.include?(name)
          seen << name

          output << rule(name, block.call)
        end

        output << "end\n"
      end

      # Formats a rule in either dialect.
      #
      def rule(name, parslet)
        "  rule #{mangle_name name}\n" <<
        "    " << parslet.accept(visitor) << "\n" <<
        "  end\n"
      end

      # Whenever the visitor encounters an rule in a parslet, it defers the
      # pretty printing of the rule by calling this method.
      #
      def deferred(name, content)
        @todo ||= []
        @todo << [name, content]
      end

      # Mangles names so that Citrus and Treetop can live with it. This mostly
      # transforms some of the things that Ruby allows into other patterns. If
      # there is collision, we will not detect it for now.
      #
      def mangle_name(str)
        str.to_s.sub(/\?$/, '_p')
      end
    end
  end
end
