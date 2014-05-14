# 
# Rakefile.rb
# 
# Load config for current environment.
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'rake'
require 'rake/testtask'

# Import external rake tasks
Dir.glob('lib/tasks/*.rake').each { |r| import r }

desc "Set up environment variables. Unless otherwise specified ROBOT_ENVIRONMENT defaults to local"
task :environment do
   environment = ENV['ROBOT_ENVIRONMENT'] || "development"
   RAILS_ENV = environment
   require File.expand_path(File.dirname(__FILE__) + "/config/environments/#{environment}")  
end


