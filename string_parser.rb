
class LiteralsParser
  include Parslet
  
  def space
    (match '[\s]').repeat(1)
  end
  
  def literals
    (literal > eol).repeat
  end
  
  def literal
    integer > space.maybe
  end
  
  def integer
    match('[0-9]').repeat(1)
  end
  
  def parse(str)
    io = StringIO.new(str)
    p [space.repeat(0), literals].map { |p| p.apply(io) }
  end
end

LiteralsParser.new.parse(
  File.read('simple.lit'))