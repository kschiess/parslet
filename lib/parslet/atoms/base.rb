# Base class for all parslets, handles orchestration of calls and implements
# a lot of the operator and chaining methods.
#
# Also see Parslet::Atoms::DSL chaining parslet atoms together.
#
class Parslet::Atoms::Base
  include Parslet::Atoms::Precedence
  include Parslet::Atoms::DSL
  include Parslet::Atoms::CanFlatten
  
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
  def parse(io, traditional=true)
    if traditional
      parse_traditional(io)
    else
      parse_vm(io)
    end
  end
  
  def parse_vm(io)
    compiler = Parslet::Bytecode::Compiler.new
    program = compiler.compile(self)
    
    vm = Parslet::Bytecode::VM.new
    vm.run(program, io)
  end
  
  def parse_traditional(io)
    source = io.respond_to?(:line_and_column) ? 
      io : 
      Parslet::Source.new(io)
    
    context = Parslet::Atoms::Context.new
    
    result = nil
    value = apply(source, context)
    
    # If we didn't succeed the parse, raise an exception for the user. 
    # Stack trace will be off, but the error tree should explain the reason
    # it failed.
    if value.error?
      @last_cause = value.message
      @last_cause.raise
    end
    
    # assert: value is a success answer
    
    # If we haven't consumed the input, then the pattern doesn't match. Try
    # to provide a good error message (even asking down below)
    unless source.eof?
      # Do we know why we stopped matching input? If yes, that's a good
      # error to fail with. Otherwise just report that we cannot consume the
      # input.
      if cause 
        # NOTE We don't overwrite last_cause here.
        raise Parslet::UnconsumedInput, 
          "Unconsumed input, maybe because of this: #{cause}"
      else
        old_pos = source.pos
        @last_cause = source.error(
          "Don't know what to do with #{source.read(100)}", old_pos)

        @last_cause.raise(Parslet::UnconsumedInput)
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
  # to #cause. 
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
    @last_cause = source.error(str, pos)
    Fail.new(@last_cause)
  end
end
