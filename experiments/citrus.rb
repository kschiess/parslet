require 'citrus'

Citrus.require File.expand_path('../ansi_smalltalk', __FILE__)
p AnsiSmalltalk.parse(File.read('test.st'))