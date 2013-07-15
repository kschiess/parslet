
# Parslet Optimizers

* Detect patterns in parsers: see section on 'Parser Pattern Detection'
* Replace with optimized parsers: see section on 'Binding and Actions'

## Parser Pattern Detection

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

Matching of 'foo' against 'foo'.