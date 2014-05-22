

# Ruby 1.9.3 is missing the charpos method on StringScanner. This file 
# retrofits that method onto StringScanner. 

require 'strscan'

s = StringScanner.new('')
unless s.respond_to? :charpos
  class StringScanner
    def charpos
      # Essentially what Ruby > 1.9 does in C. 
      string.byteslice(0,pos).size
    end
  end
end