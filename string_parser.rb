
require 'parslet'

class LiteralsParser
  include Parslet
  
  def space
    (match '[\s]').repeat(1)
  end
  
  def literals
    (literal >> eol).repeat
  end
  
  def literal
    integer >> space.maybe
  end
  
  def integer
    match('[0-9]').repeat(1)
  end
  
  def eol
    line_end.repeat(1)
  end
  
  def line_end
    crlf >> space.maybe /
    str('//') >> (crlf.absnt? >> any).repeat >> crlf >> space.maybe
  end
  
  def crlf
    match('[\r\n]')
  end
  
  def parse(str)
    (space.repeat >> literals).apply(str)
  end
end

LiteralsParser.new.parse(
  File.read('simple.lit'))