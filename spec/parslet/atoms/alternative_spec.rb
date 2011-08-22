require 'spec_helper'

describe Parslet::Atoms::Alternative do
  include Parslet
  
  describe '| shortcut' do
    let(:alternative) { str('a') | str('b') }
    
    context "when chained" do
      let!(:chained1) { alternative | str('c') }
      let!(:chained2) { alternative | str('d') }
      
      it "is side-effect free" do
        chained1.should parse('c')
        chained1.should parse('a')
        chained1.should_not parse('d')
        
        chained2.should parse('d')
        chained2.should_not parse('c')
        chained2.should parse('a')
      end 
    end
  end
end