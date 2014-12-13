require 'spec_helper'
require File.join(File.dirname(__FILE__), 'deepest_example')

describe Parslet::ErrorReporter::Deepest do
  it_behaves_like "deepest parser"
end
