# Base class for all parslets, handles orchestration of calls and implements
# a lot of the operator and chaining methods.
#
class Parslet::Atoms::Base
  include Parslet::Atoms::Precedence
  
  # Internally, all parsing functions return either an instance of Fail 
  # or an instance of Success. 
  #
  class Fail < Struct.new(:message)
    def error?; true end
  end

  # Internally, all parsing functions return either an instance of Fail 
  # or an instance of Success.
  #
  class Success < Struct.new(:result)
    def error?; false end
  end
  
  # Given a string or an IO object, this will attempt a parse of its contents
  # and return a result. If the parse fails, a Parslet::ParseFailed exception
  # will be thrown. 
  #
  def parse(io)
    source = Parslet::Source.new(io)
    context = Parslet::Atoms::Context.new
    
    result = nil
    value = apply(source, context)
    
    # If we didn't succeed the parse, raise an exception for the user. 
    # Stack trace will be off, but the error tree should explain the reason
    # it failed.
    if value.error?
      parse_failed(value.message)
    end
    
    # assert: value is a success answer
    
    # If we haven't consumed the input, then the pattern doesn't match. Try
    # to provide a good error message (even asking down below)
    unless source.eof?
      # Do we know why we stopped matching input? If yes, that's a good
      # error to fail with. Otherwise just report that we cannot consume the
      # input.
      if cause 
        # Don't garnish the real cause; but the exception is different anyway.
        raise Parslet::ParseFailed, 
          "Unconsumed input, maybe because of this: #{cause}"
      else
        old_pos = source.pos
        parse_failed(
          format_cause(source, 
            "Don't know what to do with #{source.read(100)}", old_pos))
      end
    end
    
    return flatten(value.result)
  end

  #---
  # Calls the #try method of this parslet. In case of a parse error, apply
  # leaves the source in the state it was before the attempt. 
  #+++
  def apply(source, context) # :nodoc:
    old_pos = source.pos
    
    result = context.cache(self, source) {
      try(source, context)
    }
    
    # This has just succeeded, so last_cause must be empty
    unless result.error?
      @last_cause = nil 
      return result
    end
    
    # We only reach this point if the parse has failed. Rewind the input.
    source.pos = old_pos
    return result # is instance of Fail
  end
  
  # Override this in your Atoms::Base subclasses to implement parsing
  # behaviour. 
  #
  def try(source, context)
    raise NotImplementedError, \
      "Atoms::Base doesn't have behaviour, please implement #try(source, context)."
  end

  # Construct a new atom that repeats the current atom min times at least and
  # at most max times. max can be nil to indicate that no maximum is present. 
  #
  # Example: 
  #   # match any number of 'a's
  #   str('a').repeat     
  #
  #   # match between 1 and 3 'a's
  #   str('a').repeat(1,3)
  #
  def repeat(min=0, max=nil)
    Parslet::Atoms::Repetition.new(self, min, max)
  end
  
  # Returns a new parslet atom that is only maybe present in the input. This
  # is synonymous to calling #repeat(0,1). Generated tree value will be 
  # either nil (if atom is not present in the input) or the matched subtree. 
  #
  # Example: 
  #   str('foo').maybe
  #
  def maybe
    Parslet::Atoms::Repetition.new(self, 0, 1, :maybe)
  end

  # Chains two parslet atoms together as a sequence. 
  #
  # Example: 
  #   str('a') >> str('b')
  #
  def >>(parslet)
    Parslet::Atoms::Sequence.new(self, parslet)
  end

  # Chains two parslet atoms together to express alternation. A match will
  # always be attempted with the parslet on the left side first. If it doesn't
  # match, the right side will be tried. 
  #
  # Example:
  #   # matches either 'a' OR 'b'
  #   str('a') | str('b')
  #
  def |(parslet)
    Parslet::Atoms::Alternative.new(self, parslet)
  end
  
  # Tests for absence of a parslet atom in the input stream without consuming
  # it. 
  # 
  # Example: 
  #   # Only proceed the parse if 'a' is absent.
  #   str('a').absnt?
  #
  def absnt?
    Parslet::Atoms::Lookahead.new(self, false)
  end

  # Tests for presence of a parslet atom in the input stream without consuming
  # it. 
  # 
  # Example: 
  #   # Only proceed the parse if 'a' is present.
  #   str('a').prsnt?
  #
  def prsnt?
    Parslet::Atoms::Lookahead.new(self, true)
  end

  # Marks a parslet atom as important for the tree output. This must be used 
  # to achieve meaningful output from the #parse method. 
  #
  # Example:
  #   str('a').as(:b) # will produce {:b => 'a'}
  #
  def as(name)
    Parslet::Atoms::Named.new(self, name)
  end

  # Takes a mixed value coming out of a parslet and converts it to a return
  # value for the user by dropping things and merging hashes. 
  #
  def flatten(value, named=false) # :nodoc:
    # Passes through everything that isn't an array of things
    return value unless value.instance_of? Array

    # Extracts the s-expression tag
    tag, *tail = value

    # Merges arrays:
    result = tail.
      map { |e| flatten(e) }            # first flatten each element
      
    case tag
      when :sequence
        return flatten_sequence(result)
      when :maybe
        return named ? result.first : result.first || ''
      when :repetition
        return flatten_repetition(result, named)
    end
    
    fail "BUG: Unknown tag #{tag.inspect}."
  end

  # Lisp style fold left where the first element builds the basis for 
  # an inject. 
  #
  def foldl(list, &block)
    return '' if list.empty?
    list[1..-1].inject(list.first, &block)
  end
  
  # Flatten results from a sequence of parslets. 
  #
  def flatten_sequence(list) # :nodoc:
    foldl(list.compact) { |r, e|        # and then merge flat elements
      merge_fold(r, e)
    }
  end
  def merge_fold(l, r) # :nodoc:
    # equal pairs: merge. ----------------------------------------------------
    if l.class == r.class
      if l.is_a?(Hash)
        warn_about_duplicate_keys(l, r)
        return l.merge(r)
      else
        return l + r
      end
    end
    
    # unequal pairs: hoist to same level. ------------------------------------
    
    # Maybe classes are not equal, but both are stringlike?
    if l.respond_to?(:to_str) && r.respond_to?(:to_str)
      # if we're merging a String with a Slice, the slice wins. 
      return r if r.respond_to? :to_slice
      return l if l.respond_to? :to_slice
      
      fail "NOTREACHED: What other stringlike classes are there?"
    end
    
    # special case: If one of them is a string/slice, the other is more important 
    return l if r.respond_to? :to_str
    return r if l.respond_to? :to_str
    
    # otherwise just create an array for one of them to live in 
    return l + [r] if r.class == Hash
    return [l] + r if l.class == Hash
    
    fail "Unhandled case when foldr'ing sequence."
  end

  # Flatten results from a repetition of a single parslet. named indicates
  # whether the user has named the result or not. If the user has named
  # the results, we want to leave an empty list alone - otherwise it is 
  # turned into an empty string. 
  #
  def flatten_repetition(list, named) # :nodoc:
    if list.any? { |e| e.instance_of?(Hash) }
      # If keyed subtrees are in the array, we'll want to discard all 
      # strings inbetween. To keep them, name them. 
      return list.select { |e| e.instance_of?(Hash) }
    end

    if list.any? { |e| e.instance_of?(Array) }
      # If any arrays are nested in this array, flatten all arrays to this
      # level. 
      return list.
        select { |e| e.instance_of?(Array) }.
        flatten(1)
    end
    
    # Consistent handling of empty lists, when we act on a named result        
    return [] if named && list.empty?
            
    # If there are only strings, concatenate them and return that. 
    foldl(list) { |s,e| s+e }
  end

  def self.precedence(prec) # :nodoc:
    define_method(:precedence) { prec }
  end
  precedence BASE
  def to_s(outer_prec=OUTER) # :nodoc:
    if outer_prec < precedence
      "("+to_s_inner(precedence)+")"
    else
      to_s_inner(precedence)
    end
  end
  def inspect # :nodoc:
    to_s(OUTER)
  end

  # Cause should return the current best approximation of this parslet
  # of what went wrong with the parse. Not relevant if the parse succeeds, 
  # but needed for clever error reports. 
  #
  def cause # :nodoc:
    @last_cause && @last_cause.to_s || nil
  end
  def cause? # :nodoc:
    !!@last_cause
  end

  # Error tree returns what went wrong here plus what went wrong inside 
  # subexpressions as a tree. The error stored for this node will be equal
  # with #cause. 
  #
  def error_tree
    Parslet::ErrorTree.new(self)
  end
private

  # Produces an instance of Success and returns it. 
  #
  def success(result)
    Success.new(result)
  end

  # Produces an instance of Fail and returns it. 
  #
  def error(source, str, pos=nil)
    @last_cause = format_cause(source, str, pos)
    Fail.new(@last_cause)
  end

  # Signals to the outside that the parse has failed. Use this in conjunction
  # with #format_cause for nice error messages. 
  #
  def parse_failed(cause)
    @last_cause = cause
    raise Parslet::ParseFailed,
      @last_cause.to_s
  end
  
  class Cause < Struct.new(:message, :source, :pos)
    def to_s
      line, column = source.line_and_column(pos)
      message + " at line #{line} char #{column}."
    end
  end

  # Appends 'at line ... char ...' to the string given. Use +pos+ to override
  # the position of the +source+. This method returns an object that can 
  # be turned into a string using #to_s.
  #
  def format_cause(source, str, pos=nil)
    real_pos = (pos||source.pos)
    Cause.new(str, source, real_pos)
  end

  # That annoying warning 'Duplicate subtrees while merging result' comes 
  # from here. You should add more '.as(...)' names to your intermediary tree.
  #
  def warn_about_duplicate_keys(h1, h2)
    d = h1.keys & h2.keys
    unless d.empty?
      warn "Duplicate subtrees while merging result of \n  #{self.inspect}\nonly the values"+
           " of the latter will be kept. (keys: #{d.inspect})"
    end
  end
end
