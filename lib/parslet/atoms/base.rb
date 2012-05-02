# Base class for all parslets, handles orchestration of calls and implements
# a lot of the operator and chaining methods.
#
# Also see Parslet::Atoms::DSL chaining parslet atoms together.
#
class Parslet::Atoms::Base
  include Parslet::Atoms::Precedence
  include Parslet::Atoms::DSL
  include Parslet::Atoms::CanFlatten
  
  # Given a string or an IO object, this will attempt a parse of its contents
  # and return a result. If the parse fails, a Parslet::ParseFailed exception
  # will be thrown. 
  #
  def parse(io, options={})
    source = io.respond_to?(:line_and_column) ? 
      io : 
      Parslet::Source.new(io)

    # Try to cheat. Assuming that we'll be able to parse the input, don't 
    # run error reporting code. 
    success, value = setup_and_apply(source, nil)
    
    # If we didn't succeed the parse, raise an exception for the user. 
    # Stack trace will be off, but the error tree should explain the reason
    # it failed.
    unless success
      # Cheating has not paid off. Now pay the cost: Rerun the parse,
      # gathering error information in the process.
      success, value = setup_and_apply(source, Parslet::ErrorReporter::Tree.new)
      
      fail "Assertion failed: success was true when parsing with reporter" \
        if success
      
      # Value is a Parslet::Cause, which can be turned into an exception:
      value.raise
    end
    
    # assert: success is true
    
    # If we haven't consumed the input, then the pattern doesn't match. Try
    # to provide a good error message (even asking down below)
    if !options[:prefix] && !source.eof?
      old_pos = source.pos
      Parslet::Cause.format(
        source, old_pos, 
        "Don't know what to do with #{source.read(10).to_s.inspect}").
        raise(Parslet::UnconsumedInput)
    end
    
    return flatten(value)
  end
  
  # Creates a context for parsing and applies the current atom to the input. 
  # Returns the parse result. 
  #
  # @return [<Boolean, Object>] Result of the parse. If the first member is 
  #   true, the parse has succeeded. 
  def setup_and_apply(source, error_reporter)
    context = Parslet::Atoms::Context.new(error_reporter)
    apply(source, context)
  end

  #---
  # Calls the #try method of this parslet. In case of a parse error, apply
  # leaves the source in the state it was before the attempt. 
  #+++
  def apply(source, context) # :nodoc:
    old_pos = source.pos
    
    success, value = result = context.cache(self, source) {
      try(source, context)
    }

    return result if success
    
    # We only reach this point if the parse has failed. Rewind the input.
    source.pos = old_pos
    return result
  end
  
  # Override this in your Atoms::Base subclasses to implement parsing
  # behaviour. 
  #
  def try(source, context)
    raise NotImplementedError, \
      "Atoms::Base doesn't have behaviour, please implement #try(source, context)."
  end

  # Debug printing - in Treetop syntax. 
  #
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
private

  # Produces an instance of Success and returns it. 
  #
  def succ(result)
    [true, result]
  end
end
