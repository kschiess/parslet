# Encoding: UTF-8

require 'spec_helper'

describe Parslet::Position do
  slet(:position) { described_class.new('öäüö', 4) }

  its(:charpos) { should == 2 }
  its(:bytepos) { should == 4 } 
end