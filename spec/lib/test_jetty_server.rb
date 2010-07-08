# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# A singleton class for starting/stopping a Solr server for testing purposes
# The behavior of TestSolrServer can be modified prior to start() by changing 
# port, solr_home, and quiet properties.

class TestJettyServer
  require 'singleton'
  include Singleton
  attr_accessor :port, :jetty_home, :solr_home, :fedora_home, :quiet

  # configure the singleton with some defaults
  def initialize
    @pid = nil
  end

  def self.wrap(params = {})
    error = false
    jetty_server = self.instance
    jetty_server.quiet = params[:quiet] || true
    jetty_server.jetty_home = params[:jetty_home]
    jetty_server.solr_home = params[:solr_home]
    jetty_server.fedora_home = params[:fedora_home]
    jetty_server.port = params[:jetty_port] || 8888
    begin
      puts "starting jetty server on #{RUBY_PLATFORM}"
      jetty_server.start
      
      puts "Waiting for #{params[:startup_wait] || 20} seconds..."
      sleep params[:startup_wait] || 20
      # system "netstat -an | grep LIST"
      yield
    rescue
      error = $!
      puts "*** Jetty Startup Error: #{error}"
    ensure
      puts "stopping jetty server"
      jetty_server.stop
    end

    return error
  end
  
  def jetty_command
    "cd #{@jetty_home}; java -Djetty.port=#{@port} -Dsolr.solr.home=#{@solr_home} -jar start.jar"
  end
  
  def start
    puts "jetty_home: #{@jetty_home}"
    puts "solr_home: #{@solr_home}"
    puts "fedora_home: #{@fedora_home}"
    puts "jetty_command: #{jetty_command}"
    platform_specific_start
  end
  
  def stop
    platform_specific_stop
  end
  
  if RUBY_PLATFORM =~ /mswin32/
    require 'win32/process'

    # start the solr server
    def platform_specific_start
      Dir.chdir(@jetty_home) do
        @pid = Process.create(
              :app_name         => jetty_command,
              :creation_flags   => Process::DETACHED_PROCESS,
              :process_inherit  => false,
              :thread_inherit   => true,
              :cwd              => "#{@jetty_home}"
           ).process_id
      end
    end

    # stop a running solr server
    def platform_specific_stop
      Process.kill(1, @pid)
      Process.wait
    end
  else # Not Windows
    
    def jruby_raise_error?
      raise 'JRuby requires that you start solr manually, then run "rake spec" or "rake features"' if defined?(JRUBY_VERSION)
    end
    
    # start the solr server
    def platform_specific_start
      
      jruby_raise_error?
      
      Dir.chdir(@jetty_home) do
        @pid = fork do
          STDERR.close if @quiet
          exec jetty_command
        end        
      end
    end

    # stop a running solr server
    def platform_specific_stop
      jruby_raise_error?
      Process.kill('TERM', @pid)
      `for i in \`ps -o pid,ppid,command -ax | grep jetty | awk '{print $1}'\`; do kill -9 $i; done`
      Process.wait
    end
  end

end
# 
# puts "hello"
# SOLR_PARAMS = {
#   :quiet => ENV['SOLR_CONSOLE'] ? false : true,
#   :jetty_home => ENV['SOLR_JETTY_HOME'] || File.expand_path('../../jetty'),
#   :jetty_port => ENV['SOLR_JETTY_PORT'] || 8888,
#   :solr_home => ENV['SOLR_HOME'] || File.expand_path('test')
# }
# 
# # wrap functional tests with a test-specific Solr server
# got_error = TestSolrServer.wrap(SOLR_PARAMS) do
#   puts `ps aux | grep start.jar` 
# end
# 
# raise "test failures" if got_error
# 