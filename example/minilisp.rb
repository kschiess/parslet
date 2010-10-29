# Reproduces [1] using parslet. 
# [1] http://thingsaaronmade.com/blog/a-quick-intro-to-writing-a-parser-using-treetop.html

$:.unshift '../lib'

require 'pp'
require 'parslet'

module MiniLisp
  class Parser
    include Parslet
        
    root :expression
    rule(:expression) {
      space? >> str('(') >> space? >> body >> str(')')
    }
    
    rule(:body) {
      (expression | identifier | float | integer | string).repeat.as(:exp)
    }
    
    rule(:space) {
      match('\s').repeat(1)
    }
    rule(:space?) {
      space.maybe
    }
    
    rule(:identifier) { 
      (match('[a-zA-Z=*]') >> match('[a-zA-Z=*_]').repeat).as(:identifier) >> space?
    }
    
    rule(:float) { 
      (
        integer >> (
          str('.') >> match('[0-9]').repeat(1) |
          str('e') >> match('[0-9]').repeat(1)
        ).as(:e)
      ).as(:float) >> space?
    }
    
    rule(:integer) {
      ((str('+') | str('-')).maybe >> match("[0-9]").repeat(1)).as(:integer) >> space?
    }
    
    rule(:string) {
      str('"') >> (
        str('\\') >> any |
        str('"').absnt? >> any 
      ).repeat.as(:string) >> str('"') >> space?
    }
  end
  
  class LispExp
    def initialize(parts)
      @parts = parts
    end
    def to_ary
      @parts.map { |e| e.respond_to?(:to_ary) ? e.to_ary : e }
    end
    alias :to_a :to_ary
  end

  class Transform
    include Parslet
    
    attr_reader :t
    def initialize
      @t = Parslet::Transform.new
      
      # To understand these, take a look at what comes out of the parser. 
      t.rule(:identifier => simple(:ident)) { |d| 
        d[:ident].to_sym }
        
      t.rule(:string => simple(:str)) { |d| 
        d[:str] }
        
      t.rule(:integer => simple(:int)) { |d| 
        Integer(d[:int]) }
        
      t.rule(:float=>{:integer=> simple(:a), :e=> simple(:b)}) { |d| 
        Float(d[:a] + d[:b]) }
        
      t.rule(:exp => sequence(:exp)) { |d| 
        LispExp.new(d[:exp]) }
    end
    
    def do(tree)
      t.apply(tree)
    end
  end
end

parser = MiniLisp::Parser.new
transform = MiniLisp::Transform.new

# Parse stage
begin
  result = parser.parse('(this "is" a test( 1 2.0 3))')
rescue Parslet::ParseFailed => failure
  puts failure
  puts parser.root.error_tree.ascii_tree
end

# Transform the result
pp transform.do(result).to_ary

# Thereby reducing it to the earlier problem: 
# http://github.com/kschiess/toylisp

