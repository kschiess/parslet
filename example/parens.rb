$:.unshift '../lib'

require 'pp'
require 'parslet'

class ParensParser
  include Parslet
  
  rule(:balanced) {
    str('(').as(:l) >> balanced.maybe.as(:m) >> str(')').as(:r)
  }
  
  def parse(str)
    balanced.parse(str)
  end
end

class ParensTransform
  include Parslet
  
  attr_reader :t
  def initialize
    @t = Transform.new
    
    t.rule(:l => '(', :m => simple(:x), :r => ')') { |d| 
      previous = d[:x]
      
      previous.nil? ? 1 : previous+1 }
  end
  
  def apply(tree)
    t.apply(tree)
  end
end

parser = ParensParser.new
transform = ParensTransform.new
%w!
  ()
  (())
  ((((()))))
  ((())
!.each do |pexp|
  begin
    result = parser.parse(pexp)
    puts "#{"%20s"%pexp}: #{result.inspect} (#{transform.apply(result)} parens)"
  rescue Parslet::Atoms::ParseFailed => m
    puts "#{"%20s"%pexp}: #{m}"
  end
  puts
end
