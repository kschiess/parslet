
require 'spec_helper'


describe 'Parslet and unconsumed input' do

  class MyParser < Parslet::Parser

    rule(:nl)      { match('[\s]').repeat(1) }
    rule(:nl?)     { nl.maybe }
    rule(:sp)      { str(' ').repeat(1) }
    rule(:sp?)     { str(' ').repeat(0) }
    rule(:line)    { sp >> str('line') }
    rule(:body)    { ((line | block) >> nl).repeat(0) }
    rule(:block)   { sp? >> str('begin') >> sp >> match('[a-z]') >> nl >>
                     body >> sp? >> str('end') }
    rule(:blocks)  { nl? >> block >> (nl >> block).repeat(0) >> nl? }

    root(:blocks)
  end

  it 'parses a block' do

    MyParser.new.parse(%q{
      begin a
      end
    })
  end

  it 'parses nested blocks' do

    MyParser.new.parse(%q{
      begin a
        begin b
        end
      end
    })
  end

  it 'parses successive blocks' do

    MyParser.new.parse(%q{
      begin a
      end
      begin b
      end
    })
  end

  it 'fails gracefully on a missing end' do

    lambda {
      MyParser.new.parse(%q{
        begin a
          begin b
        end
      })
    }.should raise_error(
      Parslet::ParseFailed,
      'Failed to match sequence (NL? BLOCK (NL BLOCK){0, } NL?) at line 2 char 9.'
    )
  end

  it 'fails gracefully on a missing end (2)' do

    lambda {
      MyParser.new.parse(%q{
        begin a
        end
        begin b
          begin c
        end
      })
    }.should raise_error(
      Parslet::ParseFailed,
      #'Failed to match sequence (SP? 'begin' SP [a-z] NL BODY SP? 'end') at line 7 char 7.'
      'Failed to match sequence (NL BLOCK) at line 4 char 9.'
    )
  end
end

