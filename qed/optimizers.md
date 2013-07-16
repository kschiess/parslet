
# Parslet Accelerator

The goals of parslet were simple: Make writing PEG parsers a predictable and understandable endeavour. Some people have since claimed the word 'fun' for writing parsers, a connotation that we don't entirely oppose - otherwise why would we spend our time extending parslet?

## Dark Clouds ahead

It's all fun and games until you wrote your first thousand line long parser that works. So far, we'd like to take credit for parslet, since that is much harder to do with other parser engines. But very often, the resulting parser is rather slow - having execution times in the second range instead of the subsecond range. 

You fire up your email client and drop us a mail to the mailing list, asking: Why is parslet so slow? You'll receive the following answers: 

* Parslet is not a parser generator, but a parser engine based on Ruby. As such, it will be slower than parsers written in languages such as C. 
* Parslet's internal structure is simple and understandable. We've invested a lot of effort in making everything it does obvious and extendable. The downside of this somewhat OO-heavy approach is that we've got many objects juggling data and deep callstacks. Read: Bad use of caches and CPU time. 
* Very few big languages have parsers written in high level languages such as Ruby. For good reasons. Depending on how serious you are about writing a new language (as opposed to fiddling around), you might want to _not start with parslet at all._

It is not like we've done nothing to fix the above reasons; rather, we're doing everyhing we can *provided the main goal of simplicity and understandability is not in danger*! If you look up what has been done over the years you'll find a lot of small and large optimisations. But we've always refused to sacrifice simplicity of design to the god of optimisation, especially when it came to make a single parser faster. We want parslet to be fast in general and frankly, your parser of language X is not our concern - only insofar as it uses parslet.

But parslet needs to be useful for something, otherwise what is the point, right? We would like to make parslet as useful as possible for smaller languages and for places where execution speed isn't your only concern. A lot of languages have rapidly evolving grammars and are developed by programmers that don't have the time for hand-writing parsers in C. 

Still, what should you do once you've written your parser and speed becomes the issue? Until now, you had no real options short of rewriting the damn thing in C. That changes now; we've come up with Parslet Accelerator. The accelerator will allow you to pattern match bits of your _parser_ and replace them with bits that do the same work but faster. Really, just hot spot optimisation, but without sacrificing readability of the original parser grammar. 

## An Example

Let's consider the parser for quoted strings as an example, usually written to look something like this: 

    quote = str('"')
    quote >> (quote.absent? >> any).repeat >> quote
    
If we spell out the work parslet needs to do when matching a 1000 character string using this method, the performance problems will become obvious to you. Parslet will: 

* Match a quote
* In a loop: 
  * Try to match a quote
  * If that fails, continue, otherwise break from the loop
  * Gobble up a single char
* Match the final quote

The inner loop will be executed a 1000 times; that's a 1000 times reading a char, checking to see if it's a quote, then reading it again, etc... As a programmer, this should disturb you deeply. And the fix, pseudo-code wise, should be obvious to you. Let's look at this revised flow: 

* Match a quote
* Gobble up as many chars as possible, until we hit a quote
* Match the final quote

Ok, we've sort of cheated there in the middle - we've transformed something into a single step that is really still a loop. But as a Ruby programmer, you will not see this as a loop, but rather as a call to a more efficient library like `StringScanner`, which underlies `Parslet::Source`.

So we're pretty confident that this new parser will work faster; maybe fast even. Let's assume that we've got a `GobbleUp` atom that gobbles up chars until it hits a stop char. Our faster parser would have to look something like this: 

    quote = str('"')
    quote >> GobbleUp.new('"') >> quote
    
And all is fine. Right? We think no. You've chosen to use parslet, so you don't want to end up sprinkling your grammar which is as much specification as it is implementation with things like `GobbleUp`. Wouldn't it be nice if you could keep the parser as it is, but somehow replace the pattern of `(quote.absent? >> any).repeat` with `GobbleUp.new('"')` before doing any work with your parser? Well, you can.

    quote = str('"')
    parser = quote >> (quote.absent? >> any).repeat >> quote
    
    A = Accelerator # for making what follows a bit shorter
    optimized_parser = A.apply(
      A.rule( (A.str(:x).absent? >> any).repeat ) { GobbleUp.new(x) })
    
    optimized_parser.parse('"Parsing is now fully optimized! (tm)"')
    
(If you're interested in a bit of history, the example that triggered the discussion around accelerators is preserved in "optimizer.rb":https://github.com/kschiess/parslet/blob/master/experiments/optimizer.rb. If you look past the hacks and the optimism, you'll recognize some of the things we talk about in this document.)

## Overview

Now that the goal is defined, let us expose the details of the system proposed above. We'll start with explaining what these `Accelerator.rule` things are, how they match against your parser and how binding of variables work. (*Parslet Pattern Matching*) Then we'll explain what actions you can take once you've matched part of your parser. (*Binding and Actions*)

# Parser Pattern Matching

We'll demonstrate how pattern detection is constructed by showing what the smallest parts do first. Let's require needed libraries.

    require 'parslet'
    require 'parslet/accelerator'
    
    include Parslet
    
The whole optimizer code is inside the `Parslet::Accelerator` module. If you read that, read 'particle accelerator', not 'will make my code fast'. It is very possible to make things worse using `Parslet::Accelerator`. 
    
The simplest parser I can think of would be the one matching a simple string.

    atom = str('foo')
    expression = Accelerator.str(:x)
    binding = Accelerator.match(atom, expression)

    binding[:x].assert == 'foo'
    
Note that the above was somewhat verbose, with all these variables and all that. We'll write shorter examples from now on. 

Another simple parser is the one that matches against variants of the `match(...)` atom. Multiple forms of this exist, so we'll go through all of them. First comes a simple character range match.

    binding = Accelerator.match(
      match['a-z'],
      Accelerator.re(:x))
      
    binding[:x].assert == '[a-z]'

Note how the internal regular expression value used for the match atom is really bound to :x – we'll keep this as a convention. This also means that some parslet internas are leaked through the Accelerator API here. We consider that a feature, since working with accelerators will bring you into close contact with the atoms internas.

Also the Accelerator matcher for `Parslet.match` is called `Accelerator.re` - the reason for this should be obvious from what stands above. 

## Composite Parsers

Let's start assembling these simple parsers into more complex patterns and match those. As our first pattern, we'll consider sequences.

    binding = Accelerator.match(
      str('a') >> str('b'), 
      Accelerator.str(:x) >> Accelerator.str(:y))
      
    binding.values_at(:x, :y).assert == %w(a b)


## Binding to Values

As a side note, our parser should also respect literal value matches in the pattern and only bind to subsequent locations when the values match up. 

    binding = Accelerator.match(
      str('a') >> str('b'), 
      Accelerator.str(:x) >> Accelerator.str(:x))
  
    binding.assert == nil
    
Another property should be that literal strings passed to the pattern should be matched using ===. 

    binding = Accelerator.match(
      str('abc') >> str('bcd'), 
      Accelerator.str(/b/) >> Accelerator.str('bcd'))
  
    binding.assert == {}

The binding is empty here, since no variables were given. But lets also implement constrained variable bindings, that seems useful. The way this works is that you specify a variable you want to bind to first, and then a list of constraints that are matched by `#===`.

    A = Accelerator
    A.match(str('abc'), A.str(:x, /c/))[:x].assert == 'abc'
    A.match(str('abc'), A.str(:x, /d/)).assert == nil
   
    A.match(str('abc'), A.str(:x, /a/, /c/))[:x].assert == 'abc'
    A.match(str('abc'), A.str(:x, /a/, /d/)).assert == nil
    
Here's a quick demonstration that demonstrates that this feature equally applies to both `Accelerator.re` and `Parslet.match`. 

    A.match(match['abc'], A.re(:x, /d/)).assert == nil
    A.match(match['abc'], A.re(:x, /c/))[:x].assert == '[abc]'
   
# Bindings and Actions
   
# Closing Note

* not a pancea