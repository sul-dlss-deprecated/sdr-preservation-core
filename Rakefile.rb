# 
# Rakefile.rb
# 
# 
require 'rake'
require 'rake/testtask'
require 'hanna/rdoctask'
require 'spec/rake/spectask'

# Import external rake tasks
Dir.glob('lib/tasks/*.rake').each { |r| import r }

task :default  => :test

desc "Set up environment variables. Unless otherwise specified ROBOT_ENVIRONMENT defaults to local"
task :environment do
   environment = ENV['ROBOT_ENVIRONMENT'] || "local"
   require File.expand_path(File.dirname(__FILE__) + "/config/environments/#{environment}")  
end

desc  "Run all of the rspec examples and generate the rdocs and rcov report"
task "test" do
  Rake::Task["examples"].invoke
end

desc "Do the whole build"
task "hudson" do
  Rake::Task["jetty"].invoke
 # Rake::Task["examples_with_rcov"].invoke # jetty already runs examples_with_rcov
  Rake::Task["rdoc"].invoke
end

desc "Run RSpec examples"
Spec::Rake::SpecTask.new('examples') do |t|
  t.spec_files = FileList['spec/**/*.rb']
end

desc "Run RSpec with RCov"
Spec::Rake::SpecTask.new('examples_with_rcov') do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec,/usr/,/home/hudson']
end

desc "Run RSpec Examples wrapped in a test instance of jetty"
task :jetty do
  require File.expand_path(File.dirname(__FILE__) + '/spec/lib/test_jetty_server.rb')
  
  SOLR_PARAMS = {
    :quiet => ENV['SOLR_CONSOLE'] ? false : true,
    :jetty_home => ENV['SOLR_JETTY_HOME'] || File.expand_path('./hydra-jetty'),
    :jetty_port => ENV['SOLR_JETTY_PORT'] || 8983,
    :solr_home => ENV['SOLR_HOME'] || File.expand_path('./hydra-jetty/solr'),
    :fedora_home => ENV['FEDORA_HOME'] || File.expand_path('./hydra-jetty/fedora'),
    :startup_wait => 60
  }
  # wrap tests with a test-specific Solr server
  error = TestJettyServer.wrap(SOLR_PARAMS) do
    Rake::Task["examples_with_rcov"].invoke
    # puts `ps aux | grep start.jar` 
  end
  raise "test failures: #{error}" if error
end

desc "Generate HTML report for failing examples"
Spec::Rake::SpecTask.new('failing_examples_with_html') do |t|
  t.spec_files = FileList['failing_examples/**/*.rb']
  t.spec_opts = ["--format", "html:doc/reports/tools/failing_examples.html", "--diff"]
  t.fail_on_error = false
end