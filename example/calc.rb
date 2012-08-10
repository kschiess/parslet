# A simple integer calculator to answer the question about how to do 
# left and right associativity in parslet (PEG) once and for all. 

$:.unshift File.dirname(__FILE__) + "/../lib"

require 'rspec'
require 'parslet'
require 'parslet/rig/rspec'

class CalcParser < Parslet::Parser
  root :addition
  
  rule(:addition) {
    multiplication.as(:l) >> (add_op >> multiplication.as(:r)).repeat(1) |
    multiplication
  }
  
  rule(:multiplication) { 
    integer.as(:l) >> (mult_op >> integer.as(:r)).repeat(1) |
    integer }
  
  rule(:integer) { digit.repeat(1).as(:i) >> space? }

  rule(:mult_op) { match['*/'].as(:o) >> space? }
  rule(:add_op) { match['+-'].as(:o) >> space? }

  rule(:digit) { match['0-9'] }
  rule(:space?) { match['\s'].repeat }
end

Int    = Struct.new(:int) {
  def eval; self end
  def op(operation, other)
    left = int
    right = other.int 

    Int.new(
      case operation
        when '+'
          left + right
        when '-'
          left - right
        when '*'
          left * right
        when '/'
          left / right
      end)
  end
  def to_i
    int
  end
}
Seq    = Struct.new(:sequence) {
  def eval
    sequence.reduce { |accum, operation| 
      operation.call(accum) }
  end
}
LeftOp = Struct.new(:operation, :right) {
  def call(left)
    left = left.eval
    right = self.right.eval

    left.op(operation, right)
  end
}

class CalcTransform < Parslet::Transform
  rule(i: simple(:i)) { Int.new(Integer(i)) }
  rule(o: simple(:o), r: simple(:i)) { LeftOp.new(o, i) }
  rule(l: simple(:i)) { i }
  rule(sequence(:seq)) { Seq.new(seq) }
end

def calculate(str)
  tree = CalcParser.new.parse(str)
  CalcTransform.new.apply(tree).eval.to_i
end

# A test suite for the above parser
describe CalcParser do
  let(:p) { described_class.new }
  describe '#integer' do
    let(:i) { p.integer }
    it "parses integers" do
      i.should parse('1')
      i.should parse('123')
    end 
    it "consumes trailing white space" do
      i.should parse('123   ')
    end 
    it "doesn't parse floats" do
      i.should_not parse('1.3')
    end 
  end
  describe '#multiplication' do
    let(:m) { p.multiplication }
    it "parses simple multiplication" do
      m.should parse('1*2')
    end
    it "parses division" do
      m.should parse('1/2')
    end 
  end
  describe '#addition' do
    let(:a) { p.addition }
    
    it "parses simple addition" do
      a.should parse('1+2')
      a.should parse('1+2+3-4')
    end 
  end
  
  describe 'whole computation specs' do
    def self.result_of(str, int)
      it(str) { calculate(str).should == int } 
    end

    result_of '1+1', 2
    result_of '1-1-1', -1
    result_of '1+1+3*5/2', 9
  end
end
describe CalcTransform do
  def t(obj)
    described_class.new.apply(obj)
  end
  
  it "transforms integers" do
    t(i: '1').should == Int.new(1)
  end 
  it "unwraps left operand" do
    t(l: :obj).should == :obj
  end 
end

RSpec::Core::Runner.run([], $stderr, $stdout)

str = ARGV.join
unless str.match(/\s+/)
  puts 
  print "You're asking me for the result of #{str}: -> "
  puts calculate(ARGV.join)
end