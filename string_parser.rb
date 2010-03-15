require 'pp'
require 'parslet'

class LiteralsParser
  include Parslet
  
  def space
    (match '[ ]').repeat(1)
  end
  
  def literals
    (literal >> eol).repeat
  end
  
  def literal
    (integer / string) >> space.maybe
  end
  
  def string
    str('"') >> 
    (
      (str('\\') >> any) /
      (str('"').absnt? >> any)
    ).repeat >> 
    str('"')
  end
  
  def integer
    match('[0-9]').repeat(1)
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

pp LiteralsParser.new.parse(
  File.read('simple.lit'))