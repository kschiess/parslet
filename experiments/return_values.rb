def pair
  [true, "123"]
end

Success = Struct.new(:value)
def struct
  Success.new("123")
end

class SuccessO
  def initialize(value)
    @value = value
  end
end
def klass
  SuccessO.new("123")
end

n = 1000_000
require 'benchmark'
Benchmark.bmbm(9) do |bm|
  bm.report(:pair)    { n.times do pair end }
  bm.report(:struct)  { n.times do struct end }
  bm.report(:klass)  { n.times do klass end }
end