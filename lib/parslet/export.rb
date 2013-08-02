# Allows exporting parslet grammars to other lingos.

require 'set'
require 'parslet/atoms/visitor'
require_relative "export/grammer"
require_relative "export/citrus"
require_relative "export/treetop"
require_relative "export/pretty_printer"

class Parslet::Parser
  module Visitors

  end

  # Exports the current parser instance as a string in the Citrus dialect.
  #
  # Example:
  #
  #   require 'parslet/export'
  #   class MyParser < Parslet::Parser
  #     root(:expression)
  #     rule(:expression) { str('foo') }
  #   end
  #
  #   MyParser.new.to_citrus # => a citrus grammar as a string
  #
  def to_citrus
    PrettyPrinter.new(Visitors::Citrus).
      pretty_print(self.class.name, root)
  end

  # Exports the current parser instance as a string in the Treetop dialect.
  #
  # Example:
  #
  #   require 'parslet/export'
  #   class MyParser < Parslet::Parser
  #     root(:expression)
  #     rule(:expression) { str('foo') }
  #   end
  #
  #   MyParser.new.to_treetop # => a treetop grammar as a string
  #
  def to_treetop
    PrettyPrinter.new(Visitors::Treetop).
      pretty_print(self.class.name, root)
  end
end

