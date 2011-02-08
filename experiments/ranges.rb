require 'benchmark'

# Create a larg-ish file and close the handle to it. It'll be in
# cache, but that's to be expected for parslet as well. 
File.open('test.txt', 'w') do |f|
  1000.times do
    f.puts "abc"*40
  end
end

def nothing; end

class Position
  def initialize(source, start, length, buf)
    @source, @start, @length = source, start, length
  end
end

def read_sequentially
  File.open('test.txt') do |f|
    until f.eof?
      buf = f.read(1)
      pos = Position.new(f, f.pos, 1, buf)
      nothing if buf == 'a'
    end
  end
end

def read_chunked(blocksize=500)
  File.open('test.txt') do |f|
    until f.eof?
      buf = f.read(blocksize)
      
      # To simulate what we do in read_sequentially, we'll slice
      # the buffer up into as many 1-byte chunks as it permits.
      buf.size.times do |idx|
        pos = Position.new(f, f.pos+idx, 1, buf[idx,1])
        nothing if buf[idx,1] == 'a'
      end
    end
  end
end

Benchmark.bmbm do |bm|
  bm.report('read(1):   ') { read_sequentially }
  bm.report('read(500): ') { read_chunked }
  bm.report('read(1024):') { read_chunked(1024) }
  bm.report('read(4096):') { read_chunked(4096) }
end
