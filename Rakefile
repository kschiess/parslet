
require 'rake/clean'

# Clean _site so that everything we look at is new
CLEAN << '_site'

desc "Runs the site through jekyll, producing _site"
task :compile_site do
  sh "jekyll"
end

task :default => :compile_site