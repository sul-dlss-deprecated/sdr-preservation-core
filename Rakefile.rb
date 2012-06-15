# 
# Rakefile.rb
# 
#
# Note: rake v 0.9.0 seems to have a bug that causes error messages like:
#     undefined method `desc' for #<Cucumber::Rake::Task ...
# see:
#    http://stackoverflow.com/questions/5287121/undefined-method-task-using-rake-0-9-0
# The fix is to uninstall v 0.9.0 and use v 0.8.7
# v 0.9.0 was installed in the global gemset on my system -- Richard

require 'rake'
require 'rake/testtask'
require 'rspec/core/rake_task'
#require 'jettywrapper'

# Import external rake tasks
Dir.glob('lib/tasks/*.rake').each { |r| import r }

task :default  => :spec
task :hudson  => [:test_with_jetty, :yard]


desc "Set up environment variables. Unless otherwise specified ROBOT_ENVIRONMENT defaults to local"
task :environment do
   environment = ENV['ROBOT_ENVIRONMENT'] || "development"
   RAILS_ENV = environment
   require File.expand_path(File.dirname(__FILE__) + "/config/environments/#{environment}")  
   ActiveFedora::SolrService.register( SOLR_URL )
end

desc "Run RSpec with RCov"
RSpec::Core::RakeTask.new('spec') do |t|
  t.pattern = FileList['spec/unit_tests/*.rb']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec,/usr/,/home/hudson']
end

desc "Run RSpec Examples wrapped in a test instance of jetty"
task :test_with_jetty do
  if (ENV['RAILS_ENV'] == "test")
    jetty_params = { 
      :jetty_home => File.expand_path(File.dirname(__FILE__) + '/hydra-jetty'), 
      :quiet => false, 
      :jetty_port => 8983, 
      :solr_home => File.expand_path(File.dirname(__FILE__) + '/hydra-jetty/solr'),
      :fedora_home => File.expand_path(File.dirname(__FILE__) + '/hydra-jetty/fedora/default'),
      :startup_wait => 30
      }
    error = Jettywrapper.wrap(jetty_params) do  
      Rake::Task["spec"].invoke
    end
    raise "test failures: #{error}" if error
  else
    system("rake hudson RAILS_ENV=test")
  end
end

# Use yard to build docs
begin
  require 'yard'
  require 'yard/rake/yardoc_task'

  project_root = File.expand_path(File.dirname(__FILE__))
  puts "project_root = #{project_root}"
  doc_destination = File.join(project_root, 'doc')


  YARD::Rake::YardocTask.new do |yt|
    yt.files = Dir.glob(File.join(project_root, 'robots', '**', '*.rb')) +
                 [ File.join(project_root, 'README.rdoc') ]
    yt.options = ['--readme', 'README.rdoc']
  end
rescue LoadError
  desc "Generate YARD Documentation"
  task :doc do
    abort "Please install the YARD gem to generate rdoc."
  end
end
