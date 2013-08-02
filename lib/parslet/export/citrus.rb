module Parslet
  class Parser
    module Visitors
      class Citrus
        include Export::Grammer

        def initialize(context)
          @context = context
        end


      end
    end
  end
end

module Parslet
  class Parser
    # Exports the current parser instance as a string in the Citrus dialect.
    #
    # Example:
    #
    #   require 'parslet/export'
    #   class MyParser < Parslet::Parser
    #     root(:expression)
    #     rule(:expression) { str('foo') }
    #   end
    #
    #   MyParser.new.to_citrus # => a citrus grammar as a string
    #
    def to_citrus
      PrettyPrinter.new(Visitors::Citrus).pretty_print(self.class.name, root)
    end
  end
end
