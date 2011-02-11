RSpec::Matchers.define(:parse) do |input, opts|
  chain(:as) { |as| @as = as }

  match do |parser|
    begin
      @result = parser.parse(input)
      @as == @result or @as.nil?
    rescue Parslet::ParseFailed
      @trace = parser.error_tree.ascii_tree if opts && opts[:trace]
      false
    end
  end

  failure_message_for_should do |is|
    "expected " << 
      (@as ?
        "output of parsing #{input.inspect} with #{is.inspect} to equal #{@as.inspect}, but was #{@result.inspect}" :
        "#{is.inspect} to be able to parse #{input.inspect}") << 
      (@trace ? 
        "\n"+@trace : '')
  end

  failure_message_for_should_not do |is|
    "expected " << 
      (@as ?
        "output of parsing #{input.inspect} with #{is.inspect} not to equal #{@as.inspect}" :
        "#{is.inspect} to not parse #{input.inspect}, but it did")
  end
end
