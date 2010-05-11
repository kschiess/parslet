
Spec::Runner.configure do |config|
  config.mock_with :flexmock
end

def p(*args)
  print "<pre>"+args.inspect.gsub(/</, '&lt;')+"</pre>"
end