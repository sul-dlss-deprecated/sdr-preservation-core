$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "robots")

require 'rubygems'

# Load the environment file based on Environment.  Default to local
if(ENV.include?('ROBOT_ENVIRONMENT'))
  environment = ENV['ROBOT_ENVIRONMENT']
else
  environment = 'development'
end

puts "loading environment #{environment}"

require File.expand_path(File.dirname(__FILE__) + "/../config/environments/#{environment}")
  
ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/..") unless defined?(ROBOT_ROOT)

require 'sdr_deposit'