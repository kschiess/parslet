require 'spec_helper'
require 'parslet/rspec'

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
end
