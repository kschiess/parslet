
require 'treetop'

$:.unshift File.dirname(__FILE__)
require 'ansi_smalltalk'


parser = AnsiSmalltalkParser.new
result = parser.parse(File.read("test.st"))

if !result
  puts parser.failure_reason
  puts parser.failure_line
  puts parser.failure_column
end

p result