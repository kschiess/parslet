
require 'parslet'

RSpec.configure do |config|
  config.mock_with :flexmock
end

def p(*args)
  print "<pre>"+args.map { |a| a.inspect.gsub(/</, '&lt;') }.join("\n") +"</pre>"
end