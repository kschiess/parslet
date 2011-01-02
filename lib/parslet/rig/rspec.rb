require 'rspec/expectations'

RSpec::Matchers.define(:parse) do |input|
  chain(:as) { |as| @as = as }

  match do |parser|
    begin
      @result = parser.parse(input)
      @as == @result or @as.nil?
    rescue Parslet::ParseFailed
      false
    end
  end

  failure_message_for_should do |is|
    "expected " << (@result ?
      "output of parsing #{input.inspect} with #{is.inspect} to equal #{@as.inspect}, but was #{@result.inspect}" :
      "expected #{is.inspect} to be able to parse #{input.inspect}")
  end

  failure_message_for_should_not do |is|
    "expected " << (@as ?
      "output of parsing #{input.inspect} with #{is.inspect} not to equal #{@as.inspect}" :
      "expected #{is.inspect} to be able to parse #{input.inspect}")
  end
end
