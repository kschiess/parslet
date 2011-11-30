module Parslet::Bytecode
  class VM
    def run(program, io)
      init(program, io)
      
      loop do
        instruction = fetch
        break unless instruction

        instruction.run(self)
      end
      
      return @values.last
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
  end
end