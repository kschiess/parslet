require 'site'

class FailSite < Site
  def format_documentation_line
    value_str = format_values
    "#@code# raises #{value_str}"
  end
  def format_values
    return 'NOT REACHED!' if @values.empty?
    
    v = @values.last
    s = v.inspect
    
    s = s[1..-1]
    
    s.size > 47 ? s[0,47] + '...' : s
  end

  def check
    return true if !@expectation || @expectation.match(/^\s*$/)

    str = format_values
    if str != @expectation
      puts "      #{@code.strip} # raises #{str.red}"
      puts "      #{' '*@code.strip.size} # expected: #@expectation"
    else
      puts "      #{@code.strip} # raises #{str.green}"
    end
  end
  def store(msg)
    store_if(:raised, msg)
  end
end