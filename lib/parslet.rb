require 'stringio'

module Parslet
  module Matchers
    class ParseFailed < Exception; end
    
    class Base
      def parse(io)
        if io.respond_to? :to_str
          io = StringIO.new(io)
        end
        
        result = apply(io)
        
        error(io.pos, "Don't know what to do with #{io.read.inspect}") unless io.eof?
        return flatten(result)
      end
      
      def apply(io)
        # p [:start, self, io.string[io.pos, 10]]
        
        old_pos = io.pos
        
        begin
          r = try(io)
          # p [:return_from, self, r]
          return r
        rescue ParseFailed => ex
          # p [:failing, self]
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
      def as(name)
        Named.new(self, name)
      end

      def flatten(value)
        # Passes through everything that isn't an array of things
        return value unless value.instance_of? Array

        # Extracts the s-expression tag
        tag, *tail = value
        
        # Merges arrays:
        result = tail.
          map { |e| flatten(e) }            # first flatten each element
          
        if tag == :sequence
          result.inject('') { |r, e|        # and then merge flat elements
            case [r, e].map { |o| o.class }
              when [Hash, Hash]
                warn_about_duplicate_keys(r, e)
                r.merge(e)
              when [String, String]
                r << e
            else
              if r.instance_of? Hash
                r   # Ignore e, since its not a hash we can merge
              else
                e   # Whatever e is at this point, we keep it
              end
            end
          }
        else
          if result.any? { |e| e.instance_of?(Hash) }
            result.select { |e| e.instance_of?(Hash) }
          else
            result.inject('') { |s,e| s<<e }
          end
        end
      end
    private    
      def error(position, str)
        raise ParseFailed, "#{str} at char #{position}."
      end
      def warn_about_duplicate_keys(h1, h2)
        d = h1.keys & h2.keys
        unless d.empty?
          warn "Duplicate subtrees while merging result of \n  #{self.inspect}\nonly the values"+
               " of the latter will be kept. (keys: #{d.inspect})"
        end
      end
    end
    
    class Named < Base
      attr_reader :parslet, :name
      def initialize(parslet, name)
        @parslet, @name = parslet, name
      end
      
      def apply(io)
        value = parslet.apply(io)
        
        produce_return_value value
      end
      
      def inspect
        "#{name}:#{parslet.inspect}"
      end
    private
      def produce_return_value(val)  
        { name => flatten(val) }
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

      def inspect
        if positive
          "&(#{bound_parslet.inspect})"
        else
          "!(#{bound_parslet.inspect})"
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

      def inspect
        '(' + alternatives.map { |a| a.inspect }.join(' / ') + ')'
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
        [:sequence]+parslets.map { |p| p.apply(io) }
      end
      
      def inspect
        '('+ parslets.map { |p| p.inspect }.join(' ') + ')'
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
        result = [:repetition]
        loop do
          begin
            result << parslet.apply(io)
          rescue ParseFailed => ex
            # p [:repetition, occ, min, max]
            raise ex if occ < min
            raise ex if max && occ > max
            return result
          end
          occ += 1
        end
      end
      
      def inspect
        '(' + parslet.inspect + "){#{min}, #{max}}"
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

      def inspect
        match.to_s
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
      
      def inspect
        "'#{str}'"
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

