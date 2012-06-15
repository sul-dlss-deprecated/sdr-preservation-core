ENV['RSPEC'] = "true"

require 'rspec'
require 'equivalent-xml'


include Sdr

def fixture_setup
  @fixtures = Pathname.new(File.dirname(__FILE__)).join('fixtures')
  @temp = Pathname.new(File.dirname(__FILE__)).join('temp')
  @temp.mkpath
  @temp = @temp.realpath
end

RSpec.configure do |config|
  config.before(:all) {fixture_setup}
  config.before(:each) {}
  config.after(:all) {}
  config.after(:each) {}
end
