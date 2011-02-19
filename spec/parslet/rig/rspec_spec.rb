require 'spec_helper'
require 'parslet/rig/rspec'

describe 'rspec integration' do
  include Parslet
  subject { str('example') }

  it { should parse('example') }
  it { should_not parse('foo') }
  it { should parse('example').as('example') }
  it { should_not parse('foo').as('example') }
  it { should_not parse('example').as('foo') }

  it { str('foo').as(:bar).should parse('foo').as({:bar => 'foo'}) }
  it { str('foo').as(:bar).should_not parse('foo').as({:b => 'f'}) }

  it 'accepts a block to assert more specific details about the parsing output' do
    str('foo').as(:bar).should(parse('foo').as { |output|
      output.should have_key(:bar)
      output.values.first.should == 'foo'
    })
  end

  # it { str('foo').should parse('foo').as('bar') }
  # it { str('foo').should parse('food') }
  # it { str('foo').should_not parse('foo').as('foo') }
  # it { str('foo').should_not parse('foo') }
end
