module Parslet
  module Matchers
    class ParseFailed < Exception; end
    
    class Base
      def apply(io)
        if io.respond_to? :to_str
          io = StringIO.new(io)
        end
        
        old_pos = io.pos
        
        begin
          try(io)
        rescue ParseFailed => ex
          io.pos = old_pos; raise ex
        end
      end
      
      def repeat(min=0)
        Repetition.new(self, min, nil)
      end
      def maybe
        Repetition.new(self, 0, 1)
      end
      def >>(parslet)
        Sequence.new(self, parslet)
      end
      def /(parslet)
        Alternative.new(self, parslet)
      end
      def absnt?
        Lookahead.new(self, false)
      end
      def prsnt?
        Lookahead.new(self, true)
      end
    end
    
    class Lookahead < Base
      attr_reader :positive
      attr_reader :bound_parslet
      
      def initialize(bound_parslet, positive=true)
        # Model positive and negative lookahead by testing this flag.
        @positive = positive
        @bound_parslet = bound_parslet
      end
      
      def try(io)
        pos = io.pos
        begin
          bound_parslet.apply(io)
        rescue ParseFailed 
          return fail()
        ensure 
          io.pos = pos
        end
        return success()
      end
      
      def fail
        if positive
          raise(ParseFailed, "Was looking for #{bound_parslet.inspect}.")
        else
          # TODO: Squash this down to nothing? Return value handling here...
          return nil
        end
      end
      def success
        if positive
          return nil  # see above, TODO
        else
          raise(ParseFailed, "Was looking for the absence of #{bound_parslet.inspect}.")
        end
      end
    end

    class Alternative < Base
      attr_reader :alternatives
      def initialize(*alternatives)
        @alternatives = alternatives
      end
      
      def /(parslet)
        @alternatives << parslet
        self
      end
      
      def try(io)
        alternatives.each { |a|
          begin
            return a.apply(io)
          rescue ParseFailed => ex
          end
        }
        raise(ParseFailed, "Expected one of #{alternatives.inspect}.")
      end
    end
    
    class Sequence < Base
      attr_reader :parslets
      def initialize(*parslets)
        @parslets = parslets
      end
      
      def >>(parslet)
        @parslets << parslet
        self
      end
      
      def try(io)
        parslets.map { |p| p.apply(io) }
      end
    end
    
    class Repetition < Base
      attr_reader :min, :max, :parslet
      def initialize(parslet, min, max)
        @parslet = parslet
        @min, @max = min, max
      end
      
      def try(io)
        occ = 0
        result = []
        loop do
          begin
            result << parslet.apply(io)
          rescue ParseFailed => ex
            raise ex if occ < min
            raise ex if max && occ > max
            return result
          end
          occ += 1
        end
      end
    end

    class Re < Base
      attr_reader :match
      def initialize(match)
        @match = match
      end

      def try(io)
        r = Regexp.new(match)
        s = io.read(1)
        raise(ParseFailed, "Premature end of input.") unless s
        raise ParseFailed unless s.match(r)
        return s
      end
    end
    
    class Str < Base
      attr_reader :str
      def initialize(str)
        @str = str
      end
      
      def try(io)
        old_pos = io.pos
        s = io.read(str.size)
        raise(ParseFailed, "Premature end of input.") unless s && s.size==str.size
        raise(ParseFailed, "Expected #{str.inspect}, but got #{s.inspect}") unless s==str
        return s
      end
    end
  end
    
  def match(obj)
    Matchers::Re.new(obj)
  end
  def str(str)
    Matchers::Str.new(str)
  end
  def any
    Matchers::Re.new('.')
  end
end

