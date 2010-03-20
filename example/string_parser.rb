require 'pp'

$:.unshift '../lib/'
require 'parslet'
require 'rexp_matcher'

class LiteralsParser
  include Parslet
  
  def space
    (match '[ ]').repeat(1)
  end
  
  def literals
    (literal >> eol).repeat
  end
  
  def literal
    (integer / string).as(:literal) >> space.maybe
  end
  
  def string
    str('"') >> 
    (
      (str('\\') >> any) /
      (str('"').absnt? >> any)
    ).repeat.as(:string) >> 
    str('"')
  end
  
  def integer
    match('[0-9]').repeat(1).as(:integer)
  end
  
  def eol
    line_end.repeat(1)
  end
  
  def line_end
    crlf >> space.maybe
  end
  
  def crlf
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

ast = RExpMatcher.new(parsetree).
  match(:literal => {:string => :_x})     { |d| puts "string #{d[:x]}" }.
  match(:literal => {:integer => :_x})    { |d| puts "int #{d[:x]}" }
  # replace(:literal => {:integer => :_x})  { |x| IntLit.new(x) }.
  # replace(:literal => {:string => :_x})   { |x| StringLit.new(x) }.
  # replace([Lit])                          { |x| tree(x) }