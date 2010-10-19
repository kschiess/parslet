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

parser = ParensParser.new
%w!
  ()
  (())
  ((((()))))
  ((())
!.each do |pexp|
  begin
    result = parser.parse(pexp)
    puts "#{"%20s"%pexp}: #{result.inspect}"
  rescue Parslet::Atoms::ParseFailed => m
    puts "#{"%20s"%pexp}: #{m}"
  end
  puts
end
