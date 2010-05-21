module Parslet::Atoms
  module Precedence
    prec = 0
    BASE       = (prec+=1)    # everything else
    LOOKAHEAD  = (prec+=1)    # &SOMETHING
    REPETITION = (prec+=1)    # 'a'+, 'a'?
    SEQUENCE   = (prec+=1)    # 'a' 'b'
    ALTERNATE  = (prec+=1)    # 'a' / 'b'
    OUTER      = (prec+=1)    # printing is done here.
  end
  
  class ParseFailed < Exception; end
  
  # Base class for all parslets, handles orchestration of calls and implements
  # a lot of the operator and chaining methods.
  #
  class Base
    def parse(io)
      if io.respond_to? :to_str
        io = StringIO.new(io)
      end
      
      result = apply(io)
      
      # If we haven't consumed the input, then the pattern doesn't match. Try
      # to provide a good error message (even asking down below)
      unless io.eof?
        # Do we know why we stopped matching input? If yes, that's a good
        # error to fail with. Otherwise just report that we cannot consume the
        # input.
        if cause 
          raise ParseFailed, cause
        else
          error(io, "Don't know what to do with #{io.string[io.pos,100]}") 
        end
      end
      
      return flatten(result)
    end
    
    def apply(io)
      # p [:start, self, io.string[io.pos, 10]]
      
      old_pos = io.pos
      
      # p [:try, self, io.string[io.pos, 20]]
      begin
        r = try(io)
        # p [:return_from, self, flatten(r)]
        return r
      rescue ParseFailed => ex
        # p [:failing, self, io.string[io.pos, 20]]
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
            when [Hash, Hash]             # two keyed subtrees: make one
              warn_about_duplicate_keys(r, e)
              r.merge(e)
            # a keyed tree and an array (push down)
            when [Hash, Array]
              [r] + e
            when [Array, Hash]   
              r + [e]
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
          # If keyed subtrees are in the array, we'll want to discard all 
          # strings inbetween. To keep them, name them. 
          return result.select { |e| e.instance_of?(Hash) }
        end

        if result.any? { |e| e.instance_of?(Array) }
          # If any arrays are nested in this array, flatten all arrays to this
          # level. 
          return result.
            select { |e| e.instance_of?(Array) }.
            flatten(1)
        end
        
        # If there are only strings, concatenate them and return that. 
        result.inject('') { |s,e| s<<e }
      end
    end

    def self.precedence(prec)
      define_method(:precedence) { prec }
    end
    precedence Precedence::BASE
    def to_s(outer_prec)
      if outer_prec < precedence
        "("+to_s_inner(precedence)+")"
      else
        to_s_inner(precedence)
      end
    end
    def inspect
      to_s(Precedence::OUTER)
    end

    # Cause should return the current best approximation of this parslet
    # of what went wrong with the parse. Not relevant if the parse succeeds, 
    # but needed for clever error reports. 
    #
    def cause
      @last_cause
    end

    # Error tree returns what went wrong here plus what went wrong inside 
    # subexpressions as a tree. The error stored for this node will be equal
    # with #cause. 
    #
    def error_tree
      Parslet::ErrorTree.new(self) if cause?
    end
    def cause?
      not @last_cause.nil?
    end
  private
    def error(io, str)
      pre = io.string[0..io.pos]
      lines = Array(pre.lines)
      pos   = lines.last.length
      formatted_cause = "#{str} at line #{lines.count} char #{pos}."

      @last_cause = formatted_cause

      raise ParseFailed, formatted_cause
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
    
    def to_s_inner(prec)
      "#{name}:#{parslet.to_s(prec)}"
    end

    def error_tree
      parslet.error_tree
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
        return fail(io)
      ensure 
        io.pos = pos
      end
      return success(io)
    end
    
    def fail(io)
      if positive
        error(io, "lookahead: #{bound_parslet.inspect} didn't match, but should have")
      else
        # TODO: Squash this down to nothing? Return value handling here...
        return nil
      end
    end
    def success(io)
      if positive
        return nil  # see above, TODO
      else
        error(
          io, 
          "negative lookahead: #{bound_parslet.inspect} matched, but shouldn't have")
      end
    end

    precedence Precedence::LOOKAHEAD
    def to_s_inner(prec)
      char = positive ? '&' : '!'
      
      "#{char}#{bound_parslet.to_s(prec)}"
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
      error(io, "Expected one of #{alternatives.inspect}.")
    end

    precedence Precedence::ALTERNATE
    def to_s_inner(prec)
      alternatives.map { |a| a.to_s(prec) }.join(' / ')
    end

    def error_tree
      Parslet::ErrorTree.new(self, *alternatives.
        map { |child| child.error_tree })
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
      [:sequence]+parslets.map { |p| 
        # Save each parslet as potentially offending (raising an error). 
        @offending_parslet = p
        p.apply(io) 
      }
    end
        
    precedence Precedence::SEQUENCE
    def to_s_inner(prec)
      parslets.map { |p| p.to_s(prec) }.join(' ')
    end

    def cause
      @offending_parslet.cause if @offending_parslet
    end
    def cause?
      @offending_parslet && @offending_parslet.cause?
    end
    def error_tree
      @offending_parslet.error_tree if @offending_parslet
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
          occ += 1

          # If we're not greedy (max is defined), check if that has been 
          # reached. 
          return result if max && occ>=max
        rescue ParseFailed => ex
          # Greedy matcher has produced a failure. Check if occ (which will
          # contain the number of sucesses) is in {min, max}.
          # p [:repetition, occ, min, max]
          error(io, "Expected at least #{min} of #{parslet.inspect}") if occ < min
          return result
        end
      end
    end
    
    precedence Precedence::REPETITION
    def to_s_inner(prec)
      minmax = "{#{min}, #{max}}"
      minmax = '?' if min == 0 && max == 1

      parslet.to_s(prec) + minmax
    end

    def cause
      # Either the repetition failed or the parslet inside failed to repeat. 
      super || parslet.cause
    end
    def error_tree
      if cause?
        Parslet::ErrorTree.new(self, parslet.error_tree)
      else
        parslet.error_tree
      end
    end
  end

  class Re < Base
    attr_reader :match
    def initialize(match)
      @match = match
    end

    def try(io)
      r = Regexp.new(match, Regexp::MULTILINE)
      s = io.read(1)
      error(io, "Premature end of input") unless s
      error(io, "Failed to match #{match.inspect[1..-2]}") unless s.match(r)
      return s
    end

    def to_s_inner(prec)
      match.inspect[1..-2]
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
      error(io, "Premature end of input") unless s && s.size==str.size
      error(io, "Expected #{str.inspect}, but got #{s.inspect}") unless s==str
      return s
    end
    
    def to_s_inner(prec)
      "'#{str}'"
    end
  end

  class Entity < Base
    attr_reader :name, :block
    def initialize(name, block)
      super()
      
      @name = name
      @block = block
    end

    def try(io)
      parslet.apply(io)
    end
    
    def parslet
      @parslet ||= block.call
    end

    def to_s_inner(prec)
      name.upcase
    end

    def error_tree
      return nil if @mark
      begin
        @mark = true
        parslet.error_tree
      ensure 
        @mark = false
      end
    end
  end
end

