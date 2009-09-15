# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mir_utility}
  s.version = "0.2.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Corey Ehmke and Rod Monje"]
  s.date = %q{2009-09-15}
  s.description = %q{Standard extensions for Mir Rails apps.}
  s.email = %q{corey@seologic.com}
  s.extra_rdoc_files = ["CHANGELOG", "lib/mir_form_builder.rb", "lib/mir_utility.rb", "README.rdoc"]
  s.files = ["CHANGELOG", "History.txt", "init.rb", "lib/mir_form_builder.rb", "lib/mir_utility.rb", "Manifest", "mir_utility.gemspec", "Rakefile", "README.rdoc", "tmp/spec.html"]
  s.homepage = %q{http://github.com/bantik/mir_utility}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Mir_utility", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{mir_utility}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Standard extensions for Mir Rails apps.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
