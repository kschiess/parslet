# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'parslet'
  s.version = '1.2.3'

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.authors = ['Kaspar Schiess']
  s.date = Date.today
  s.email = 'kaspar.schiess@absurd.li'
  s.extra_rdoc_files = ['README']
  s.files = %w(Gemfile HISTORY.txt LICENSE Rakefile README) + Dir.glob("{lib,example}/**/*")
  s.homepage = 'http://kschiess.github.com/parslet'
  s.rdoc_options = ['--main', 'README']
  s.require_paths = ['lib']
  s.rubygems_version = '1.8.6'
  s.summary = 'Parser construction library with great error reporting in Ruby.'  
  
  s.add_dependency 'blankslate', '~> 2.0'
  
  %w(rspec flexmock rdoc sdoc guard guard-rspec growl).each { |gem_name| 
    s.add_development_dependency gem_name }
end
