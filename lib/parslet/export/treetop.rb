module Parslet
  class Parser
    module Visitors
      class Treetop
        include Export::Grammer

        def initialize(context)
          @context = context
        end

        def visit_repetition(tag, min, max, parslet)
          parslet.accept(self) << "#{min}..#{max}"
        end

        def visit_alternative(alternatives)
          "(#{alternatives.map { |el| el.accept(self) }.join(" / ")})"
        end
      end
    end
  end
end

module Parslet
  class Parser
    # Exports the current parser instance as a string in the Treetop dialect.
    #
    # Example:
    #
    #   require 'parslet/export'
    #   class MyParser < Parslet::Parser
    #     root(:expression)
    #     rule(:expression) { str('foo') }
    #   end
    #
    #   MyParser.new.to_treetop # => a treetop grammar as a string
    #
    def to_treetop
      PrettyPrinter.new(Visitors::Treetop).
        pretty_print(self.class.name, root)
    end
  end
end
