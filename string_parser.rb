class StringParser
  
  
  def parse(str)
    
  end
end

StringParser.new.parse %Q{
  "THis is a string"
  "This is another string"
  "This string is escaped \"embedded quoted stuff \" "
  12 // an integer literal and a comment
}