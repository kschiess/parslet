# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{parslet}
  s.version = "0.11.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kaspar Schiess"]
  s.date = %q{2010-11-25}
  s.email = %q{kaspar.schiess@absurd.li}
  s.extra_rdoc_files = ["README"]
  s.files = ["Gemfile", "HISTORY.txt", "LICENSE", "Rakefile", "README", "spec", "lib/parslet", "lib/parslet/atoms", "lib/parslet/atoms/alternative.rb", "lib/parslet/atoms/base.rb", "lib/parslet/atoms/entity.rb", "lib/parslet/atoms/lookahead.rb", "lib/parslet/atoms/named.rb", "lib/parslet/atoms/re.rb", "lib/parslet/atoms/repetition.rb", "lib/parslet/atoms/sequence.rb", "lib/parslet/atoms/str.rb", "lib/parslet/atoms.rb", "lib/parslet/error_tree.rb", "lib/parslet/expression", "lib/parslet/expression/treetop.rb", "lib/parslet/expression.rb", "lib/parslet/parser.rb", "lib/parslet/pattern", "lib/parslet/pattern/binding.rb", "lib/parslet/pattern/context.rb", "lib/parslet/pattern.rb", "lib/parslet/transform.rb", "lib/parslet.rb"]
  s.homepage = %q{http://kschiess.github.com/parslet}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Parser construction library with great error reporting in Ruby.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<blankslate>, ["~> 2.1.2.3"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<flexmock>, [">= 0"])
    else
      s.add_dependency(%q<blankslate>, ["~> 2.1.2.3"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<flexmock>, [">= 0"])
    end
  else
    s.add_dependency(%q<blankslate>, ["~> 2.1.2.3"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<flexmock>, [">= 0"])
  end
end
