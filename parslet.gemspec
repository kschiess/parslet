# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'parslet'
  s.version = '1.5.0'

  s.authors = ['Kaspar Schiess']
  s.email = 'kaspar.schiess@absurd.li'
  s.extra_rdoc_files = ['README']
  s.files = %w(HISTORY.txt LICENSE Rakefile README) + Dir.glob("{lib,example}/**/*")
  s.homepage = 'http://kschiess.github.com/parslet'
  s.rdoc_options = ['--main', 'README']
  s.require_paths = ['lib']
  s.summary = 'Parser construction library with great error reporting in Ruby.'  
  
  s.add_dependency 'blankslate', '~> 2.0'
  
  %w(rspec flexmock rdoc sdoc guard guard-rspec rb-fsevent growl).
    each { |gem_name| 
      s.add_development_dependency gem_name }
end
