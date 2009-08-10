require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('mir_utility', '0.2.0') do |p|
	p.description     = "Standard extensions for Mir Rails apps."
	p.url             = "http://github.com/bantik/mir_utility"
	p.author          = "Corey Ehmke and Rod Monje"
	p.email           = "corey@seologic.com"
	p.ignore_pattern  = ["tmp/*", "script/*"]
	p.development_dependencies = []
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }