# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{parslet}
  s.version = "0.9.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kaspar Schiess"]
  s.date = %q{2010-10-29}
  s.email = %q{kaspar.schiess@absurd.li}
  s.extra_rdoc_files = ["README"]
  s.files = ["Gemfile", "HISTORY.txt", "LICENSE", "Rakefile", "README", "lib/parslet/atoms.rb", "lib/parslet/error_tree.rb", "lib/parslet/pattern/binding.rb", "lib/parslet/pattern.rb", "lib/parslet/transform.rb", "lib/parslet.rb"]
  s.homepage = %q{http://kschiess.github.com/parslet}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Parser construction library with great error reporting in Ruby.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<flexmock>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<flexmock>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<flexmock>, [">= 0"])
  end
end
