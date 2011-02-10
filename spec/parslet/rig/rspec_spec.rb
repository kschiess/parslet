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

  # Uncomment to test error messages manually: 
  # it { str('foo').should parse('foo', :trace => true).as('bar') }
  # it { str('foo').should parse('food', :trace => true) }
  # it { str('foo').should_not parse('foo', :trace => true).as('foo') }
  # it { str('foo').should_not parse('foo', :trace => true) }
  # it { str('foo').should parse('foo').as('bar') }
  # it { str('foo').should parse('food') }
  # it { str('foo').should_not parse('foo').as('foo') }
  # it { str('foo').should_not parse('foo') }
end
