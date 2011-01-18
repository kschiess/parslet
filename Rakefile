
require "rubygems"
require "rake/rdoctask"
require 'rspec/core/rake_task'

desc "Run all examples"
RSpec::Core::RakeTask.new

task :default => :spec

require 'sdoc'

# Generate documentation
Rake::RDocTask.new do |rdoc|
  rdoc.title    = "parslet - construction of parsers made easy"
  rdoc.options << '--line-numbers'
  rdoc.options << '--fmt' << 'shtml' # explictly set shtml generator
  rdoc.template = 'direct' # lighter template used on railsapi.com
  rdoc.main = "README"
  rdoc.rdoc_files.include("README", "lib/**/*.rb")
  rdoc.rdoc_dir = "rdoc"
end

desc 'Clear out RDoc and generated packages'
task :clean => [:clobber_rdoc, :clobber_package]
