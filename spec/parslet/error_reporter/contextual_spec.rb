require 'spec_helper'
require File.join(File.dirname(__FILE__), 'deepest_example')

describe Parslet::ErrorReporter::Contextual do
  it_behaves_like "deepest parser"

  let(:reporter) { described_class.new }
  let(:fake_source) { flexmock('source') }
  let(:fake_atom) { flexmock('atom') }
  let(:fake_cause) { flexmock('cause') }

  describe '#reset' do
    before(:each) { fake_source.should_receive(
      :pos => Parslet::Position.new('source', 13),
      :line_and_column => [1,1]) }

    it "resets deepest cause on success of sibling expression" do
      flexmock(reporter).
        should_receive(:deepest).and_return(:deepest)
      reporter.err('parslet', fake_source, 'message').
        should == :deepest
      flexmock(reporter).
        should_receive(:reset).once
      reporter.succ(fake_source)
    end
  end

  describe 'label' do
    before(:each) { fake_source.should_receive(
      :pos => Parslet::Position.new('source', 13),
      :line_and_column => [1,1]) }

    it "sets label if atom has one" do
      fake_atom.should_receive(:label).once.and_return('label')
      fake_cause.should_receive(:set_label).once
      flexmock(reporter).
        should_receive(:deepest).and_return(fake_cause)
      reporter.err(fake_atom, fake_source, 'message').
        should == fake_cause
    end

    it 'does not set label if atom does not have one' do
      flexmock(reporter).
        should_receive(:deepest).and_return(:deepest)
      fake_atom.should_receive(:update_label).never
      reporter.err(fake_atom, fake_source, 'message').
        should == :deepest
    end
  end

end
