require 'codeclimate-test-reporter'
require 'active_record'
CodeClimate::TestReporter.start

require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'action_command'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

load File.dirname(__FILE__) + '/test_files/schema.rb'
require File.dirname(__FILE__) + '/test_files/models.rb'