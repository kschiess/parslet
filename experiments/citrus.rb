require 'citrus'

Citrus.require File.expand_path('../ansi_smalltalk', __FILE__)
AnsiSmalltalk.parse(File.read(ARGV.first || 'test.st'))