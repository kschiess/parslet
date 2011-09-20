require 'rdoc/task'
require 'sdoc'

require 'rspec/core/rake_task'
require "rubygems/package_task"

desc "Run all tests: Exhaustive."
RSpec::Core::RakeTask.new

namespace :spec do
  desc "Only run unit tests: Fast. "
  RSpec::Core::RakeTask.new(:unit) do |task|
    task.pattern = "spec/parslet/**/*_spec.rb"
  end
end

task :default => :spec

# Generate documentation
RDoc::Task.new do |rdoc|
  rdoc.title    = "parslet - construction of parsers made easy"
  rdoc.options << '--line-numbers'
  rdoc.options << '--fmt' << 'shtml' # explictly set shtml generator
  rdoc.template = 'direct' # lighter template used on railsapi.com
  rdoc.main = "README"
  rdoc.rdoc_files.include("README", "lib/**/*.rb")
  rdoc.rdoc_dir = "rdoc"
end

desc 'Clear out RDoc'
task :clean => [:clobber_rdoc, :clobber_package]

# This task actually builds the gem. 
task :gem => :spec
spec = eval(File.read('parslet.gemspec'))

desc "Generate the gem package."
Gem::PackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Prints LOC stats"
task :stat do
  %w(lib spec example).each do |dir|
    loc = %x(find #{dir} -name "*.rb" | xargs wc -l | grep 'total').split.first.to_i
    printf("%20s %d\n", dir, loc)
  end
end

