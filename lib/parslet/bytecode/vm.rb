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
        instruction = fetch
        p [@ip, instruction] if debug?
        break unless instruction

        instruction.run(self)
      end
      
      return flatten(@values.last)
    end
    
    attr_reader :source
    attr_reader :context
    
    def init(program, io)
      @ip = 0
      @program = program
      @source = Parslet::Source.new(io)
      @context = Parslet::Atoms::Context.new
      @values = []
    end
    
    def fetch
      @program.at(@ip).tap { @ip += 1 }
    end
    
    # --------------------------------------------- interface for instructions
    def push(value)
      @values.push value
    end
    def pop(n)
      @values.pop(n)
    end
    def success?
      true
    end
    def jump(address)
      @ip = address.address
    end
  end
end