require 'treetop'
require 'literals'

parser = LiteralsParser.new
p parser.parse(File.read('test.lit'))
parser.terminal_failures.each do |failure|
  puts failure
end