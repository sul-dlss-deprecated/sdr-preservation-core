$: << File.join(File.dirname(__FILE__), "./fixtures")

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "robots")
require 'spec'
 
# Make sure specs run with the definitions from test.rb
environment = ENV['ROBOT_ENVIRONMENT'] = 'test'
require File.expand_path(File.dirname(__FILE__) + "/../config/environments/#{environment}")  
