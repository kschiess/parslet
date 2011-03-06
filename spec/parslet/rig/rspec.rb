RSpec::Matchers.define(:parse) do |input, opts|
  match do |parser|
    begin
      @result = parser.parse(input)
      @block ? 
        @block.call(@result) : 
        (@as == @result || @as.nil?)
    rescue Parslet::ParseFailed
      @trace = parser.error_tree.ascii_tree if opts && opts[:trace]
      false
    end
  end

  failure_message_for_should do |is|
    if @block
      "expected output of parsing #{input.inspect}" <<
      " with #{is.inspect} to meet block conditions, but it didn't"
    else
      "expected " << 
        (@as ? 
          "output of parsing #{input.inspect}"<<
          " with #{is.inspect} to equal #{@as.inspect}, but was #{@result.inspect}" : 
          "#{is.inspect} to be able to parse #{input.inspect}") << 
        (@trace ? 
          "\n"+@trace : 
          '')
    end
  end

  failure_message_for_should_not do |is|
    if @block
      "expected output of parsing #{input.inspect} with #{is.inspect} not to meet block conditions, but it did"
    else
      "expected " << 
        (@as ? 
          "output of parsing #{input.inspect}"<<
          " with #{is.inspect} not to equal #{@as.inspect}" :
          
          "#{is.inspect} to not parse #{input.inspect}, but it did")
    end
  end

  def as(expected_output = nil, &block)
    @as = expected_output
    @block = block
    self
  end
end

RSpec::Matchers.define(:apply) do |input|
  match do |transformer|
    begin
      @result = transformer.apply(input)
      @as == @result or @as.nil?
    rescue Exception => e
      @trace = "#{e.message} #{e.backtrace.inspect}"
      false
    end
  end

  failure_message_for_should do |is|
    (@as ? 
    "expected " << 
      "output of transforming #{input.inspect}" <<
      " with #{is.inspect} to equal #{@as.inspect}, but was #{@result.inspect}" :
      "#{is.inspect} to be able to transform #{input.inspect}") << 
      (@trace ? 
        "\n"+@trace : 
        '')
  end

  failure_message_for_should_not do |is|
    "expected " << 
      (@as ? 
        "output of transforming #{input.inspect}"<<
        " with #{is.inspect} not to equal #{@as.inspect}" :
        
        "#{is.inspect} to not transform #{input.inspect}, but it did")
  end
end

