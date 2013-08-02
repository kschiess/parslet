module Parslet
  class Parser
    module Visitors
      class Treetop < Citrus
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
