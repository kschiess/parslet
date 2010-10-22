require 'pp'

$:.unshift '../lib/'
require 'parslet'

class LiteralsParser
  include Parslet
  
  rule :space do
    (match '[ ]').repeat(1)
  end
  
  rule :literals do
    (literal >> eol).repeat
  end
  
  rule :literal do
    (integer / string).as(:literal) >> space.maybe
  end
  
  rule :string do
    str('"') >> 
    (
      (str('\\') >> any) /
      (str('"').absnt? >> any)
    ).repeat.as(:string) >> 
    str('"')
  end
  
  rule :integer do
    match('[0-9]').repeat(1).as(:integer)
  end
  
  rule :eol do
    line_end.repeat(1)
  end
  
  rule :line_end do
    crlf >> space.maybe
  end
  
  rule :crlf do
    match('[\r\n]').repeat(1)
  end
  
  def parse(str)
    literals.parse(str)
  end
end

parsetree = LiteralsParser.new.parse(
  File.read('simple.lit'))
  
class Lit < Struct.new(:text)
  def to_s
    text.inspect
  end
end
class StringLit < Lit
end
class IntLit < Lit
  def to_s
    text
  end
end

transform = Parslet::Transform.new

transform.rule(:literal => {:integer => simple(:x)}) { |d| 
  IntLit.new(*d.values) }
transform.rule(:literal => {:string => simple(:x)}) { |d| 
  StringLit.new(*d.values) }
  
ast = transform.apply(parsetree)
pp ast