# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'parslet'
  s.version = '1.1.0'

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.authors = ['Kaspar Schiess']
  s.date = '2011-01-17'
  s.email = 'kaspar.schiess@absurd.li'
  s.extra_rdoc_files = ['README']
  s.files = %w(Gemfile HISTORY.txt LICENSE Rakefile README) + Dir.glob("{lib,example}/**/*")
  s.homepage = 'http://kschiess.github.com/parslet'
  s.rdoc_options = ['--main', 'README']
  s.require_paths = ['lib']
  s.rubygems_version = '1.3.7'
  s.summary = 'Parser construction library with great error reporting in Ruby.'  
  
  s.add_dependency 'blankslate', '~> 2.0'
  
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'flexmock'
end
