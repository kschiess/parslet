module Parslet
  class Parser
    module Visitors
      class Citrus
        attr_reader :context
        attr_reader :output

        def initialize(context)
          @context = context
        end

        def visit_str(str)
          %|"#{str.inspect[1..-2]}"|
        end

        def visit_re(match)
          match.to_s
        end

        def visit_entity(name, block)
          context.deferred(name, block)

          "(#{context.mangle_name(name)})"
        end

        def visit_named(name, parslet)
          parslet.accept(self)
        end

        def visit_sequence(parslets)
          "(#{parslets.map { |el| el.accept(self) }.join(" ")})"
        end

        def visit_repetition(tag, min, max, parslet)
          "#{parslet.accept(self)}#{min}*#{max}"
        end

        def visit_alternative(alternatives)
          "(#{alternatives.map { |el| el.accept(self) }.join(" | ")})"
        end

        def visit_lookahead(positive, bound_parslet)
          "#{positive ? "&" : "!"}#{bound_parslet.accept(self)}"
        end
      end
    end
  end
end
