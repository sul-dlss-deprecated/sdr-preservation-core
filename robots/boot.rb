$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "robots")

require 'rubygems'

# Load the environment file based on Environment.  Default to local
if(ENV.include?('ROBOT_ENVIRONMENT'))
  environment = ENV['ROBOT_ENVIRONMENT']
else
  environment = 'local'
end

require File.expand_path(File.dirname(__FILE__) + "/../config/environments/#{environment}")
  