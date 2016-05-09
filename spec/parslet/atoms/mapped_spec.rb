require 'spec_helper'

describe Parslet::Atoms::Mapped do
  include Parslet

  describe "map" do
    it "maps over the parse result" do
      str('a').map(lambda { |x| x.to_s.upcase }).parse('a').should == 'A'
    end
    
    it "composes maps" do
      int = match('[0-9]').repeat(1).as(:int).map(lambda { |x| x[:int].to_s.to_i })
      date = (int.as(:year) >> str('-') >> int.as(:month) >> str('-') >> int.as(:day)).map(lambda { |x| DateTime.new(x[1][:year], x[3][:month], x[5][:day]) })
      date.parse('2000-01-01').should == DateTime.new(2000,1,1)
    end
  end
end