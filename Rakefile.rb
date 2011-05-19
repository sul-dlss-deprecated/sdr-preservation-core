# 
# Rakefile.rb
# 
# 
require 'rake'
require 'rake/testtask'
require 'spec/rake/spectask'
require 'jettywrapper'

# Import external rake tasks
Dir.glob('lib/tasks/*.rake').each { |r| import r }

task :default  => :test

desc "Set up environment variables. Unless otherwise specified ROBOT_ENVIRONMENT defaults to local"
task :environment do
   environment = ENV['ROBOT_ENVIRONMENT'] || "development"
   RAILS_ENV = environment
   require File.expand_path(File.dirname(__FILE__) + "/config/environments/#{environment}")  
   ActiveFedora::SolrService.register( SOLR_URL )
end

desc  "Run all of the rspec examples and generate the rdocs and rcov report"
task "test" do
  Rake::Task["examples"].invoke
end

desc "Run RSpec examples"
Spec::Rake::SpecTask.new('examples') do |t|
  t.spec_files = FileList['spec/**/*.rb']
end

desc "Run RSpec with RCov"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec,/usr/,/home/hudson']
end

desc "Run RSpec Examples wrapped in a test instance of jetty"
task :hudson do
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

desc "Generate HTML report for failing examples"
Spec::Rake::SpecTask.new('failing_examples_with_html') do |t|
  t.spec_files = FileList['failing_examples/**/*.rb']
  t.spec_opts = ["--format", "html:doc/reports/tools/failing_examples.html", "--diff"]
  t.fail_on_error = false
end
