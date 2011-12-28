module Parslet::Bytecode
  class VM
    include Parslet::Atoms::CanFlatten
    
    def initialize(debug=false)
      @debug = debug
    end
    
    def debug?
      @debug
    end
    
    def run(program, io)
      init(program, io)
      
      loop do
        p(
          :ip => Compiler::Address.new(@ip), 
          :top => @values.last,
          :e => @error.to_s
        ) if debug?
        
        instruction = fetch
        break unless instruction
        
        p [:instr, instruction] if debug?
        p [:stack, @values.reverse[0,4], @values.size>4 ? '...' : ''] if debug?
        p [:calls, @calls] if debug?

        instruction.run(self)
        break if @stop
        
        puts if debug?
      end
      
      return flatten(@values.last) if success? && source.eof?

      if success?
        # assert: not source.eof?
        current_pos = source.pos
        source.error(
          "Don't know what to do with #{source.read(100)}", current_pos).
          raise(Parslet::UnconsumedInput)
      end

      @error.raise
      
    rescue 
      dump_state
      raise
    end
    
    attr_reader :source
    attr_reader :context
    
    def init(program, io)
      @ip = 0
      @program = program
      @source = Parslet::Source.new(io)
      @context = Parslet::Atoms::Context.new
      @values = []
      @calls  = []
      @frames = []
    end
    
    def fetch
      @program.at(@ip).tap { @ip += 1 }
    end
    
    # Dumps the VM state so that the user can track errors down.
    #
    def dump_state
      puts "\nVM STATE on exception -------------------------------- "
      puts "Program: "
      for adr in (@ip-5)..(@ip+5)
        printf("%s%5d: %s\n", 
          adr == @ip ? '->' : '  ',
          adr, 
          @program.at(adr)) if @program.at(adr)
      end
      
      puts "\nStack(#{@values.size}): (last 5, top is top of stack)"
      @values.last(5).reverse.each_with_index do |v,i|
        printf("  %5d: %s\n", i, v)
      end

      puts "\nStack Frames(#{@frames.size}): (last 5, top is top of stack)"
      @frames.last(5).reverse.each_with_index do |v,i|
        printf("  %5d: trunc stack at %s\n", i, v)
      end

      puts "\nCall Stack(#{@calls.size}): (last 5, top is top of stack)"
      @calls.last(5).reverse.each_with_index do |v,i|
        printf("  %5d: return to @%s\n", i, v)
      end
      puts "---------------------- -------------------------------- "
    end
    
    # --------------------------------------------- interface for instructions
    def push(value)
      @values.push value
    end
    def pop(n=nil)
      if n
        @values.pop(n)
      else
        @values.pop
      end
    end
    def enter_frame
      @frames.push @values.size
    end
    def discard_frame
      size = @frames.pop
      fail "No stack frame." unless size
      fail "Stack frame larger than the current stack." if size > @values.size
      @values = @values[0,size]
    end
    def jump(address)
      @ip = address.address
    end
    def success?
      !@error
    end
    def call(adr)
      @calls.push @ip
      jump(adr)
    end
    def call_ret
      @ip = @calls.pop
      fail "One pop too many - empty call stack in #call_ret." unless @ip
    end
    def set_error(error)
      @error = error
    end
    def clear_error
      @error = nil
    end
    attr_reader :error
    def stop
      @stop = true
    end
  end
end