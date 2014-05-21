
# Intro

This document collects all sorts of weird bugs that parslet had over the years and asserts that we don't accidentially reintroduce one of these. There's not much to be learnt here but a few war stories to be had. 

# Regresssions

# Github #101

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


