# Encoding: UTF-8

require 'spec_helper'

describe Parslet::Atoms::Finished do
  def ignore
    described_class.new
  end

  context 'by itself' do
    it "parses successfully" do
      ignore.should parse('あああ')
      ignore.should parse('')
      ignore.should parse("\n\r\\|/-\\|")
    end
  end
end
