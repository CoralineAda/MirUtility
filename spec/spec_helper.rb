# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require File.dirname(__FILE__) + "/../config/environment" unless defined?(RAILS_ROOT)
require 'spec/autorun'
require 'spec/rails'
require File.expand_path(File.dirname(__FILE__) + "/blueprints")
 
# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  config.before(:each) { Sham.reset }
end

# Helper methods

def login_as_client
  _user = User.make :role => ( Role.client.first || Role.make(:client) ), :state => 'active'
  login_as _user
  _user
end

def login_as_admin
  _user = User.make :role => ( Role.admin.first || Role.make(:admin) ), :state => 'active'
  login_as _user
  _user
end