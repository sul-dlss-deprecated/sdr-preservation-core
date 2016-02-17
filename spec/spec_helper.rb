ENV['RSPEC'] = "true"

require 'awesome_print'
require 'equivalent-xml'
require 'fakeweb'
require 'pry'
require 'rspec'

require 'simplecov'
require 'coveralls' if ENV['CI']

SimpleCov.formatter = Coveralls::SimpleCov::Formatter if ENV['CI']
SimpleCov.start do
  add_filter '/spec/'
end

require 'sdr'
include Sdr

def fixture_setup
  @fixtures = Pathname(__dir__).join('fixtures')
  @temp = Pathname(Dir.mktmpdir).realpath
end

RSpec.configure do |config|
  config.before(:all) {fixture_setup}
  config.before(:each) {}
  config.after(:all) {}
  config.after(:each) {}
end

