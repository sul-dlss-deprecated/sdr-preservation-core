# Make the cucumber rake task available only if cucumber is installed

  begin

    require 'cucumber'
    require 'cucumber/rake/task'

    Cucumber::Rake::Task.new(:features) do |t|
      t.cucumber_opts = "--format pretty"
    end

  rescue LoadError
    desc 'Cucumber rake task not available'
    task :features do
      abort 'Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin'
    end
  end
  
  desc "Run end to end cucumber for a specific pid"
  task :run_a_pid => :environment do
    if ENV["pid"].nil? 
      puts "You must specify a valid pid.  Example: rake cucumber:run_a_pid pid=demo:12"
    else
      pid = ENV["pid"]
      puts "processing #{pid}"
      # puts "Deleting '#{pid}' from #{Fedora::Repository.instance.fedora_url}"
      # ActiveFedora::Base.load_instance(pid).delete
      # puts "The object has been deleted."
    end
  end