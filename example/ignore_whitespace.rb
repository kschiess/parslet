# An example on how to ignore whitespace. Use the composition, luke.

$:.unshift File.dirname(__FILE__) + "/../lib"

require 'pp'
require 'parslet'
require 'parslet/convenience'

class AParser < Parslet::Parser
  root :as
  
  rule(:as) { a.repeat }
  rule(:a) { str('a').as(:a) }
end

class WsIgnoreSource
  def initialize(string)
    @io = StringIO.new(string)
    @early_eof = nil
  end
  
  def pos
    @io.pos
  end
  
  def pos=(n)
    @io.pos = n
  end
  
  def gets(buf, n)
    return nil if eof?
    
    return read(n).tap {
      @early_eof = pos unless can_read?
    }
  end
  
  def eof?
    @io.eof? ||                         # the underlying source is EOF
    @early_eof && pos >= @early_eof     # we have no non-ws chars left
  end
  
  private
  
  # Reads n chars from @io.
  def read(n)
    b = ''
    while b.size < n && !@io.eof?
      c = @io.gets(nil, 1)
      b << c unless c == ' '
    end
    b
  end
  
  # True if there are any chars left in @io.
  def can_read?
    old_pos = @io.pos
    read(1).size == 1
  rescue => ex
    return false
  ensure
    @io.pos = old_pos
  end
end

pp AParser.new.parse_with_debug(WsIgnoreSource.new('a   a a a    '))