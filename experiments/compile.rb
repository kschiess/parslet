$:.unshift File.dirname(__FILE__) + "/../lib"

require 'parslet'
include Parslet

module Parslet::Atoms
  class Str
    def compile(generator)
      generator.add_try(self)
    end
  end
  class Sequence
    attr_writer :offending_parslet
    def compile(generator)
      @parslets.each do |parslet|
        generator.add_try(parslet)
        generator.add_check_unwrap(self, parslet)
      end
      generator.add_wrap_sequence(@parslets.size)
    end
  end
end

class Buffer
  def initialize
    @instructions = []
  end
  
  def <<(instruction)
    @instructions << instruction
  end
  def at(pointer)
    @instructions[pointer]
  end

  def to_s
    s = ''
    s << "Buffer (0x#{self.object_id.to_s(16)}):\n"
    @instructions.each_with_index do |instruction, idx|
      s << sprintf(" %04d: %s\n", idx, instruction)
    end
    s
  end
end

class Generator
  def initialize(buffer)
    @buffer = buffer
  end
end

class VM
  def initialize(buffer)
    init(buffer)
  end

  def run(string)
    @source = Parslet::Source.new(string)
    @context = Parslet::Atoms::Context.new
    
    loop do
      instruction = fetch
      break if instruction.nil?
      
      instruction.run(self)
    end
    
    value = @values.last
    
    # If we didn't succeed the parse, raise an exception for the user. 
    # Stack trace will be off, but the error tree should explain the reason
    # it failed.
    if value.error?
      fail "Parse failed"
    end
    
    # If we haven't consumed the input, then the pattern doesn't match. Try
    # to provide a good error message (even asking down below)
    unless source.eof?
      fail "Unconsumed input"
    end
    
    return value.result
  end
  
  attr_reader :source
  attr_reader :context
  
  def init(buffer)
    @ip = 0
    @buffer = buffer
    @values = []
  end
  
  def fetch
    @buffer.at(@ip).tap { @ip += 1 }
  end
  
  def push(value)
    @values.push value
  end
  def pop(n=1)
    if n == 1
      @values.pop
    else
      @values.pop(n)
    end
  end
  
  def to_s
    s = '' <<
      "VM (0x#{object_id.to_s(16)}):\n" <<
      "  values: #{@values.inspect}\n" <<
      "  ip: #{@ip}"
  end
  
  # Produces an instance of Success and returns it. 
  #
  def success(result)
    Parslet::Atoms::Base::Success.new(result)
  end
  
  def self.instruction(name, *fields, &run_method)
    struct_name = name.to_s.gsub(%r{(^|_)(\w)}) { $2.upcase }
    const_set(struct_name, Struct.new(*fields) {
      define_method(:run, &run_method)
    })
    Generator.send(:define_method, "add_#{name}") do |*args|
      @buffer << VM.const_get(struct_name).new(*args)
    end
  end
  instruction(:try, :obj) do |vm|
    vm.push obj.try(vm.source, vm.context)
  end
  instruction(:check_unwrap, :obj, :parslet) do |vm|
    value = vm.pop
    if value.error?
      obj.offending_parslet = parslet
      fail 
    else
      vm.push value.result
    end
  end
  instruction(:wrap_sequence, :count) do |vm|
    # We've called check_unwrap after each match, so the n top values are 
    # parse results.
    values = vm.pop(count)
    vm.push(vm.success([:sequence, *values]))
  end
end

parser = str('foo') >> str('bar')

buffer = Buffer.new
generator = Generator.new(buffer)
parser.compile(generator)

puts buffer

def run_on(buffer, string)
  vm = VM.new(buffer)
  retval = vm.run(string)

  p [:retval, retval]
  puts vm
end


run_on buffer, 'foobar'
run_on buffer, 'babar'