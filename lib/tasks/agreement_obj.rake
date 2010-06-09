require 'lyber_core'

namespace :objects do
  

  desc "Build the bootstrap agreement object in the specified Fedora repository"
  task :build_agreement_obj do
    unless ENV['ROBOT_ENVIRONMENT']
      puts "You haven't set a value for ROBOT_ENVIRONMENT so I don't know where to build the object."
      puts "Invoke this script like this: \n ROBOT_ENVIRONMENT=test rake objects:build_agreement_obj"
    else
      puts "Building agreement obj in #{ENV['ROBOT_ENVIRONMENT']}"
      environment = ENV['ROBOT_ENVIRONMENT']
      require File.expand_path(File.dirname(__FILE__) + "/../../config/environments/#{environment}")
      puts "Connecting to #{SEDORA_URI}..."
    end
  end


end