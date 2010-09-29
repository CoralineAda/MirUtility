require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'tasks/rails'
require 'echoe'

Echoe.new('mir_utility', '0.3.28') do |p|
	p.description     = "Standard extensions for Mir Rails apps."
	p.url             = "http://github.com/bantik/mir_utility"
	p.author          = "Corey Ehmke and Rod Monje"
	p.email           = "corey@seologic.com"
	p.ignore_pattern  = ["app/**/*", "config/**/*", "db/**/*", "lib/tasks/*", "log/", "public/**/*", "script/**/*", "spec/**/*", "tmp/"]
	p.development_dependencies = []
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }
