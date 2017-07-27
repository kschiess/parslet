
# Intro

This document collects all sorts of weird bugs that parslet had over the years and asserts that we don't accidentially reintroduce one of these. There's not much to be learnt here but a few war stories to be had. 

# Regresssions

## Redefinition of Ruby core methods

This [bug](https://github.com/kschiess/parslet/issues/101) came up at least twice. When constructing a parser like this

    class HashParser < Parslet::Parser
      rule(:str_hash) { str('hash') }
      rule(:hash) { str_hash }
      rule(:expr) { hash }
      root(:expr)
    end

We're essentially redefining the parser object's #hash method here. So the parse might work, but the packrat caching doesn't - because it used to stick parsers into a hash. Now this should be impossible, because we're using the `#object_id` of the parser - a speed gain

    HashParser.new.parse('hash') # did raise a TypeError, but doesn't now

Looking back, getting this error was not only probable, but inevitable: Everyone constructs parsers for programming languages, and almost all modern programming languages know the hash as a construct. Hope this one stays buried. 

## i18n and the Difference between Byte and Character Position

This is hard to get right, especially when considering the differences between the 1.8 and 1.9 branches of Ruby. By dropping 1.8 support, we got rid of a special branch of problems, now really the only thing that remains is treating character and byte offsets consistently. Ruby itself doesn't really: 

| method                  | seeks by/returns  |
|-------------------------|-------------------|
| `String#[]`             | character         |
| `StringScanner#pos`     | byte              |
| `StringScanner#pos=`    | byte              |
| `StringScanner#charpos` | character         |

In parslet, we adopt the following conventions: 

* `Source#bytepos` and `Source#bytepos=` only deal in byte positions. We don't have a choice here, since StringScanner only seeks to byte locations, probably for speed reasons. These methods are used internally for parsing, caching and resetting the parse. 
* `Source#pos` returns character positions. This method is used for returning positions associated to slices. 

So let's test if we get this right by using input composed of the unicode chars 'öäü', mainly because I can type those easily on this keyboard. 

    class I18NParser < Parslet::Parser
      rule(:nl) { str("\n") }
      rule(:ouml) { str("ö") }
      rule(:auml) { str("ä") }
      rule(:expr) { ((ouml | auml).repeat(1).as(:line) >> nl).repeat(1) }
      root(:expr)
    end

    result = I18NParser.new.parse("äö\nä\nö\n")

    [{ofs: 0, line: 1, col: 1}, 
     {ofs: 3, line: 2, col: 1}, 
     {ofs: 5, line: 3, col: 1}].zip(result).each do |expect, capture|
      capture[:line].offset.assert == expect[:ofs]
      capture[:line].line_and_column.assert == expect.values_at(:line, :col)
    end 


