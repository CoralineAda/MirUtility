# Loads the contents of config.yml into the hash APP_CONFIG. Usage:

# APP_CONFIG['mail'] returns a hash of mail's children
# APP_CONFIG['mail']['port'] returns the value of the specified key in mail

config_file = "#{RAILS_ROOT}/config/config.yml"

if File.exist?(config_file)
  APP_CONFIG = YAML.load_file( config_file )[RAILS_ENV]
  
  puts "Found configuration...\n#{APP_CONFIG.inspect}" unless RAILS_ENV == "test"

else
  puts "Can't find config file #{config_file}!"
  puts "Rename config/config_example.yml to config.yml and customize as necessary."
  exit
end
