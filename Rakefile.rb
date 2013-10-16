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

# Load config for current environment.
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'rake'
require 'rake/testtask'
require 'rspec/core/rake_task'

require 'jettywrapper'

# Import external rake tasks
Dir.glob('lib/tasks/*.rake').each { |r| import r }

task :default  => :spec
task :hudson  => [:test_with_jetty]


desc "Set up environment variables. Unless otherwise specified ROBOT_ENVIRONMENT defaults to local"
task :environment do
   environment = ENV['ROBOT_ENVIRONMENT'] || "development"
   RAILS_ENV = environment
   require File.expand_path(File.dirname(__FILE__) + "/config/environments/#{environment}")  
   ActiveFedora::SolrService.register( SOLR_URL )
end

desc "Run RSpec"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/sdr*/*.rb'
  t.rspec_opts = ['--backtrace']
end

# see: http://stackoverflow.com/questions/8886258/rcov-for-rspec-2-not-detecting-coverage-correctly-not-rails
# There seems to be an issue with RCov and RSpec (>2.6.0) where the coverage percentage just doesn't make sense anymore
# see also: http://stackoverflow.com/questions/2218362/rcov-why-is-this-code-not-being-considered-covered
# and http://stackoverflow.com/questions/8859748/rcov-code-coverage-issue
# I am using rcov (0.9.11), ruby 1.8.7, Rails 3.1, spec 2.7. The coverage report shows some of the code as having 0% coverage but I have test coverage for it. When I modify the code with 0% coverage, I get failing tests.
desc "Run RSpec with RCov"
RSpec::Core::RakeTask.new(:spec_rcov) do |t|
  t.rcov = true
  t.verbose = true
  t.pattern = 'spec/sdr*/*.rb'
  t.rspec_opts = [ "-f documentation"]
  t.rcov_opts = ['--exclude /gems/,/Library/,/usr/,spec,lib/tasks']
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

