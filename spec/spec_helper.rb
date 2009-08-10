ENV["RAILS_ENV"] = "test"

require 'rubygems'
require 'multi_rails_init'
require 'active_record'
require 'active_record/version'
require 'active_record/fixtures'
require 'action_controller'
require 'action_controller/test_process'
require 'action_view'
require 'test/unit'
require 'shoulda'
require 'matchy'
require 'spec'
require 'spec/rails'
$:.unshift(File.dirname(__FILE__) + '/../lib')

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => "mir_utility.sqlite3")

# FIXME: replace with the schema that we actually want to use for testing.
# ActiveRecord::Schema.define(:version => 1) do
# Ê create_table :posts do |t|
# Ê Ê t.string :title
# Ê Ê t.text :excerpt, :body
# Ê end
# end

# FIXME: define classes 

class ApplicationController < ActionController::Base
  include MirUtility
end

# class Post < ActiveRecord::Base
# Ê validates_presence_of :title
# end

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  # 
  # For more information take a look at Spec::Runner::Configuration and Spec::Runner
end

# Helper methods

