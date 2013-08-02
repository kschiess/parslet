
  - [![Gem Version](https://badge.fury.io/rb/parslet.png)](https://rubygems.org/gems/parslet)
  - [![Code Quality](https://codeclimate.com/github/kschiess/parslet.png)](https://codeclimate.com/github/kschiess/parslet)
  - [![Build Status](https://travis-ci.org/kschiess/parslet.png)](https://travis-ci.org/kschiess/parslet)
  - [![Dependency Status](https://gemnasium.com/kschiess/parslet.png)](https://gemnasium.com/kschiess/parslet)
  - [![Coverage Status](https://coveralls.io/repos/kschiess/parslet/badge.png?branch=master)](https://coveralls.io/r/kschiess/parslet)


INTRODUCTION
------------

Parslet makes developing complex parsers easy. It does so by

* providing the best error reporting possible
* not generating reams of code for you to debug

Parslet takes the long way around to make your job easier. It allows for
incremental language construction. Often, you start out small, implementing
the atoms of your language first; _parslet_ takes pride in making this
possible.

Eager to try this out? Please see the associated web site:
http://kschiess.github.com/parslet


SYNOPSIS
--------

  require 'parslet'
  include Parslet

  # parslet parses strings
  str('foo').
    parse('foo') # => "foo"@0

  # it matches character sets
  match['abc'].parse('a') # => "a"@0
  match['abc'].parse('b') # => "b"@0
  match['abc'].parse('c') # => "c"@0

  # and it annotates its output
  str('foo').as(:important_bit).
    parse('foo') # => {:important_bit=>"foo"@0}

  # you can construct parsers with just a few lines
  quote = str('"')
  simple_string = quote >> (quote.absent? >> any).repeat >> quote

  simple_string.
    parse('"Simple Simple Simple"') # => "\"Simple Simple Simple\""@0

  # or by making a fuss about it
  class Smalltalk < Parslet::Parser
    root :smalltalk

    rule(:smalltalk) { statements }
    rule(:statements) {
      # insert smalltalk parser here (outside of the scope of this readme)
    }
  end

  # and then
  Smalltalk.new.parse('smalltalk')

COMPATIBILITY
-------------

This library should work with most rubies. I've tested it with MRI 1.8
(except 1.8.6), 1.9, rbx-head, jruby. Please report as a bug if you encounter
issues.

Note that due to Ruby 1.8 internals, Unicode parsing is not supported on that
version.

On Mac OS X Lion, ruby-1.8.7-p352 has been known to segfault. Use
ruby-1.8.7-p334 for better results.


STATUS
------

Production worthy.

Copyright (c) 2013 Kaspar Schiess

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
