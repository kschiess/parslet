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
        old_ip = @ip
        instruction = fetch
        break unless instruction
        
        # Diagnostics
        printf("executing %5d: %s\n", old_ip, instruction) if debug?

        # Run the current instruction
        instruction.run(self)
        
        # Diagnostics
        dump_state(0) if debug?
        break if @stop
      end

      fail "Stack contains too many values." if @values.size>1

      # In the best case, we have successfully matched and consumed all input. 
      # This is what we want, from now on down it's all error cases.
      return flatten(@values.last) if success? && source.eof?

      # Maybe we've matched some, but not all of the input? In parslets books, 
      # this is an error as well. 
      if success?
        # assert: not source.eof?
        current_pos = source.pos
        source.error(
          "Don't know what to do with #{source.read(100)}", current_pos).
          raise(Parslet::UnconsumedInput)
      end

      # assert: ! @error.nil?

      # And maybe we just could not do it for a reason. Raise that. 
      @error.raise
      
    rescue => ex
      dump_state(-1) unless ex.kind_of?(Parslet::ParseFailed)
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
      @cache  = {}
    end
    
    def fetch
      @program.at(@ip).tap { @ip += 1 }
    end
    
    # Dumps the VM state so that the user can track errors down.
    #
    def dump_state(ip_offset)
      return unless debug?
      puts "\nVM STATE -------------------------------------------- "
      
      old_pos = source.pos
      debug_pos = old_pos - 10
      source.pos = debug_pos < 0 ? 0 : debug_pos
      puts "Source: #{source.read(20)}"
      puts (" "*"Source: ".size) << (" "*(10+(debug_pos<0 ? debug_pos : 0))) << '^'
      source.pos = old_pos
      
      if @error
        puts "Error register: #{@error}"
      else 
        puts "Error register: EMPTY"
      end
      
      puts "Program: "
      for adr in (@ip-5)..(@ip+5)
        printf("%s%5d: %s\n", 
          adr == @ip+ip_offset ? '->' : '  ',
          adr, 
          @program.at(adr)) if adr >= 0 && @program.at(adr)
      end
      
      puts "\nStack(#{@values.size}): (last 5, top is top of stack)"
      @values.last(5).reverse.each_with_index do |v,i|
        printf("  %5d: %s\n", i, v.inspect)
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
    def access_cache(skip_adr)
      key = [source.pos, @ip-1]
      
      # Is the given vm state in the cache yet?
      if @cache[key]
        # Restore state
        success, value, advance = @cache[key]
        
        if success
          push value 
        else 
          set_error value
        end
        
        source.pos += advance
        
        # Skip to skip_adr
        jump skip_adr
        return true
      end
      
      return false
    end
    def store_cache(adr)
      if success?
        pos, result = pop(2)
        key = [pos, adr.address]
        @cache[key] = [true, result, source.pos-pos]
        push result
      else
        pos = pop
        key = [pos, adr.address]
        @cache[key] = [false, @error, source.pos-pos]
      end
    end
    def push(value)
      @values.push value
    end
    def pop(n=nil)
      if n
        fail "Stack corruption detected, popping too many values (#{n}/#{@values.size})." \
          if n>@values.size
            
        @values.pop(n)
      else
        fail "Stack corruption detected, popping too many values. (stack is empty)" \
          if @values.empty?
        
        @values.pop
      end
    end
    def value_at(ptr)
      @values.at(-ptr-1)
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