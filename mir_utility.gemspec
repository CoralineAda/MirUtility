# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mir_utility}
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Corey Ehmke and Rod Monje"]
  s.date = %q{2009-08-10}
  s.description = %q{Standard extensions for Mir Rails apps.}
  s.email = %q{corey@seologic.com}
  s.extra_rdoc_files = ["CHANGELOG", "lib/tasks/rspec.rake", "README.rdoc", "TODO.txt"]
  s.files = ["app/controllers/application.rb", "app/controllers/home_controller.rb", "app/helpers/application_helper.rb", "app/models/user.rb", "app/views/home/index.html.erb", "app/views/home/test_error.html.erb", "app/views/layouts/application.html.erb", "CHANGELOG", "config/environments/development.rb", "config/environments/production.rb", "config/environments/test.rb", "config/initializers/formats.rb", "config/initializers/inflections.rb", "config/initializers/load_config.rb", "config/initializers/logs.rb", "config/initializers/mime_types.rb", "config/initializers/new_rails_defaults.rb", "config/initializers/site_keys.rb", "config/locales/en.yml", "db/migrate/20090226212641_create_users.rb", "db/migrate/20090226212642_create_roles.rb", "db/migrate/999_create_models_for_testing.rb", "History.txt", "init.rb", "lib/tasks/rspec.rake", "Manifest", "mir_utility.gemspec", "public/images/icons/collapsed.gif", "public/images/icons/delete.png", "public/images/icons/edit.png", "public/images/icons/expanded.gif", "public/images/icons/help_icon.png", "public/images/icons/view.png", "public/images/icons/warning_icon.png", "public/images/layout/footer_bg.png", "public/images/layout/header_bg_grey.png", "public/images/layout/navigation_bg.png", "public/images/layout/navigation_bg_on.png", "public/images/layout/text_field_bg.jpg", "public/images/rails.png", "public/javascripts/application.js", "public/javascripts/controls.js", "public/javascripts/dragdrop.js", "public/javascripts/effects.js", "public/javascripts/prototype.js", "public/stylesheets/core.css", "Rakefile", "README.rdoc", "script/performance/benchmarker", "script/performance/profiler", "script/performance/request", "script/process/inspector", "script/process/reaper", "script/process/spawner", "spec/lib/mir_utility_spec.rb", "TODO.txt"]
  s.homepage = %q{http://github.com/bantik/mir_utility}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Mir_utility", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{mir_utility}
  s.rubygems_version = %q{1.3.4}
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
