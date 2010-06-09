
namespace :objects do

  desc "Build the bootstrap agreement object in the current Fedora repository"
  task :build_agreement_obj do
    unless ENV['ROBOT_ENVIRONMENT']
      puts "You haven't set a value for ROBOT_ENVIRONMENT so I don't know where to build the object."
      puts "Invoke this script like this: \n ROBOT_ENVIRONMENT=test rake objects:build_agreement_obj"
    else
      puts "Building agreement obj in #{ENV['ROBOT_ENVIRONMENT']}"
    end
  end


end