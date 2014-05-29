# 
# Rakefile.rb
# 
require_relative 'lib/libdir'
require 'rake'
require 'rake/testtask'

# Import external rake tasks
Dir.glob('lib/tasks/*.rake').each { |r| import r }

desc "Set up environment variables. Unless otherwise specified ROBOT_ENVIRONMENT defaults to local"
task :environment do
   environment = ENV['ROBOT_ENVIRONMENT'] || "development"
   RAILS_ENV = environment
   require_relative "config/environments/#{environment}"
end


