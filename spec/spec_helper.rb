$: << File.join(File.dirname(__FILE__), "./fixtures")

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "robots")
require 'spec'
require 'pathname'
 
# Make sure specs run with the definitions from test.rb
environment = ENV['ROBOT_ENVIRONMENT'] = 'test'
require File.expand_path(File.dirname(__FILE__) + "/../config/environments/#{environment}")  
ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/..") unless defined?(ROBOT_ROOT)

def fixture_setup
  @fixtures = Pathname.new(ROBOT_ROOT).join('spec/fixtures')
end

Spec::Runner.configure do |config|
  config.before(:all) {fixture_setup}
  config.before(:each) {}
  config.after(:all) {}
  config.after(:each) {}
end
