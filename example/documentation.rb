$:.unshift '../lib'

require 'pp'
require 'parslet'

class MyParser
  include Parslet

  rule(:a) { str('a').repeat }
  
  def parse(str)
    a.parse(str)
  end
end

pp MyParser.new.parse('aaaa')
pp MyParser.new.parse('bbbb')
