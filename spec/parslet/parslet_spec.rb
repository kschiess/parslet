require 'spec_helper'

describe Parslet do
  include Parslet
  
  describe Parslet::ParseFailed do
    it "should be caught by an empty rescue" do
      begin
        raise Parslet::ParseFailed
      rescue
        # Success! Ignore this.
      end
    end 
  end
  describe "<- .rule" do
    # Rules define methods. This can be easily tested by defining them right 
    # here. 
    context "empty rule" do
      rule(:empty) { }
      
      it "should raise a NotImplementedError" do
        lambda {
          empty.parslet
        }.should raise_error(NotImplementedError)
      end 
    end
    
    context "containing 'any'" do
      rule(:any_rule) { any }
      subject { any_rule }
      
      it { should be_a Parslet::Atoms::Entity }
      it "should memoize the returned instance" do
        any_rule.object_id.should == any_rule.object_id
      end 
    end
    
    context "with options" do
      describe ":repeat" do
        context "when `true` is passed" do
          rule(:space, repeat: true) { str(' ') }
          subject { spaces }
          after { undef :space, :spaces }
          
          it { should be_a Parslet::Atoms::Entity }
        end
        
        context "when a Hash is passed" do
          describe ":min" do
            rule(:space, repeat: { min: 5 }) { str(' ') }
            subject { spaces }
            after { undef :space, :spaces }
            
            it { should be_a Parslet::Atoms::Entity }
            
            it "should parse a minimum of 5 spaces" do
              subject.parse('     ')
              subject.parse('      ')
              
              cause = catch_failed_parse { subject.parse('') }
              cause.to_s.should == "Expected at least 5 of SPACE at line 1 char 1."
            end
          end
          
          describe ":max" do
            rule(:space, repeat: { max: 5 }) { str(' ') }
            subject { spaces }
            after { undef :space, :spaces }
            
            it { should be_a Parslet::Atoms::Entity }
            
            it "should parse a maximum of 5 spaces" do
              subject.parse('   ')
              subject.parse('    ')
              
              cause = catch_failed_parse { subject.parse('       ') }
              cause.to_s.should == "Don't know what to do with \"  \" at line 1 char 6."
            end
          end
          
          describe ":predicate" do
            rule(:space, repeat: { predicate: true }) { str(' ') }
            subject { spaces? }
            after { undef :space, :spaces, :spaces? }
            
            it { should be_a Parslet::Atoms::Entity }
            
            it "should maybe parse multiple spaces" do
              subject.parse('')
              subject.parse(' ')
              subject.parse('  ')
              
              cause = catch_failed_parse { subject.parse('a') }
              cause.to_s.should == "Extra input after last repetition at line 1 char 1."
            end
          end
        end
      end
      
      describe ":predicate" do
        rule(:space, predicate: true) { str(' ') }
        subject { space? }
        after { undef :space, :space? }
        
        it { should be_a Parslet::Atoms::Entity }
        
        it "should maybe parse 1 space" do
          subject.parse('')
          subject.parse(' ')
          
          cause = catch_failed_parse { subject.parse('  ') }
          cause.to_s.should == "Don't know what to do with \" \" at line 1 char 2."
        end
      end
    end
  end
end