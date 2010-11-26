module Parslet::Atoms
  # The precedence module controls parenthesis during the #inspect printing
  # of parslets. It is not relevant to other aspects of the parsing. 
  #
  module Precedence # :nodoc:
    prec = 0
    BASE       = (prec+=1)    # everything else
    LOOKAHEAD  = (prec+=1)    # &SOMETHING
    REPETITION = (prec+=1)    # 'a'+, 'a'?
    SEQUENCE   = (prec+=1)    # 'a' 'b'
    ALTERNATE  = (prec+=1)    # 'a' | 'b'
    OUTER      = (prec+=1)    # printing is done here.
  end
  
  autoload :Base,         'parslet/atoms/base'
  autoload :Named,        'parslet/atoms/named'
  autoload :Lookahead,    'parslet/atoms/lookahead'
  autoload :Alternative,  'parslet/atoms/alternative'
  autoload :Sequence,     'parslet/atoms/sequence'
  autoload :Repetition,   'parslet/atoms/repetition'
  autoload :Re,           'parslet/atoms/re'
  autoload :Str,          'parslet/atoms/str'
  autoload :Entity,       'parslet/atoms/entity'
end

