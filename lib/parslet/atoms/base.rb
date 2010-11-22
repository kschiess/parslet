# Base class for all parslets, handles orchestration of calls and implements
# a lot of the operator and chaining methods.
#
class Parslet::Atoms::Base
  include Parslet::Atoms::Precedence
  
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
        raise Parslet::ParseFailed, "Unconsumed input, maybe because of this: #{cause}"
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
      @last_cause = nil
      return r
    rescue Parslet::ParseFailed => ex
      # p [:failing, self, io.string[io.pos, 20]]
      io.pos = old_pos; raise ex
    end
  end
  
  def repeat(min=0, max=nil)
    Parslet::Atoms::Repetition.new(self, min, max)
  end
  def maybe
    Parslet::Atoms::Repetition.new(self, 0, 1, :maybe)
  end
  def >>(parslet)
    Parslet::Atoms::Sequence.new(self, parslet)
  end
  def |(parslet)
    Parslet::Atoms::Alternative.new(self, parslet)
  end
  def absnt?
    Parslet::Atoms::Lookahead.new(self, false)
  end
  def prsnt?
    Parslet::Atoms::Lookahead.new(self, true)
  end
  def as(name)
    Parslet::Atoms::Named.new(self, name)
  end

  def flatten(value)
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
        return result.first
      when :repetition
        return flatten_repetition(result)
    end
    
    fail "BUG: Unknown tag #{tag.inspect}."
  end
  def flatten_sequence(list)
    list.inject('') { |r, e|        # and then merge flat elements
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
          # Now e is either nil, in which case we drop it, or something else. 
          # If it is something else, it is probably more important than r, 
          # since we've checked for important values of r above. 
          e||r
        end
      end
    }
  end
  def flatten_repetition(list)
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
    
    # If there are only strings, concatenate them and return that. 
    list.inject('') { |s,e| s<<(e||'') }
  end

  def self.precedence(prec)
    define_method(:precedence) { prec }
  end
  precedence BASE
  def to_s(outer_prec)
    if outer_prec < precedence
      "("+to_s_inner(precedence)+")"
    else
      to_s_inner(precedence)
    end
  end
  def inspect
    to_s(OUTER)
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
  # Report/raise a parse error with the given message, printing the current
  # position as well. Appends 'at line X char Y.' to the message you give. 
  # If +pos+ is given, it is used as the real position the error happened, 
  # correcting the io's current position.
  #
  def error(io, str, pos=nil)
    pre = io.string[0..(pos||io.pos)]
    lines = Array(pre.lines)
    
    if lines.empty?
      formatted_cause = str
    else
      pos   = lines.last.length
      formatted_cause = "#{str} at line #{lines.count} char #{pos}."
    end

    @last_cause = formatted_cause
    
    raise Parslet::ParseFailed, formatted_cause, nil
  end
  def warn_about_duplicate_keys(h1, h2)
    d = h1.keys & h2.keys
    unless d.empty?
      warn "Duplicate subtrees while merging result of \n  #{self.inspect}\nonly the values"+
           " of the latter will be kept. (keys: #{d.inspect})"
    end
  end
end
