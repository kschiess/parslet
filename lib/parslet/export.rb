# Allows exporting parslet grammars to other lingos. 

require 'set'
require 'parslet/atoms/visitor'

class Parslet::Parser
  module Citrus
    class Visitor
      attr_reader :context, :output
      def initialize(context)
        @context = context
        @output = StringIO.new
      end
      
      def str(str)
        output.print "\"#{str.inspect[1..-2]}\""
      end
      def re(match)
        output.print match.inspect
      end

      def entity(name, ctx, block)
        context.deferred(name, [ctx, block])

        output.print "(#{context.mangle_name(name)})"
      end
      def named(name, parslet)
        parslet.accept(self)
      end

      def sequence(parslets)
        output.print '('
        parslets.each do |parslet|
          parslet.accept(self)
          output.print ' ' unless parslet == parslets.last
        end
        output.print ')'
      end
      def repetition(min, max, parslet)
        parslet.accept(self)
        output.print "#{min}*#{max}"
      end
      def alternative(alternatives)
        alternatives.each do |parslet|
          parslet.accept(self)
          output.print " | " unless parslet == alternatives.last
        end
      end

      def lookahead(positive, bound_parslet)
        output.print (positive ? '&' : '!')
        bound_parslet.accept(self)
      end

      def reset
        @output.string.tap {
          @output = StringIO.new
        }
      end
    end
  end

  class PrettyPrinter
    attr_reader :visitor
    def initialize(visitor_klass)
      @visitor = visitor_klass.new(self)
    end

    def pretty_print(name, parslet)
      output = "grammar #{name}\n"
      
      output << "  rule root\n"
      parslet.accept(visitor)
      output << "    " << visitor.reset << "\n"
      output << "  end\n"
      
      seen = Set.new
      loop do
        break if @todo.empty?
      
        name, (context, block) = @todo.shift
        next if seen.include?(name)
        
        seen << name
        
        output << "  rule #{mangle_name name}\n"
        context.instance_eval(&block).
          accept(visitor)
        output << "    " << visitor.reset << "\n"
        output << "  end\n"
      end
      
      output << "end\n"
    end
    
    def deferred(name, content)
      @todo ||= []
      @todo << [name, content]
    end

    def mangle_name(str)
      str.to_s.sub(/\?$/, '_p')
    end
  end

  
  def to_citrus
    PrettyPrinter.new(Citrus::Visitor).
      pretty_print(self.class.name, root)
  end
end

