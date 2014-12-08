ENV['RSPEC'] = "true"

require 'awesome_print'
require 'equivalent-xml'
require 'fakeweb'
require 'pry'
require 'rspec'
require 'simplecov'
SimpleCov.start

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

