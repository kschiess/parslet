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
