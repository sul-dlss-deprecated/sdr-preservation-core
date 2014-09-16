# make sure the lib folder is in the search path, and load the boot.rb file from that path
libdir = File.expand_path('../../../lib')
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
require 'boot'

# load all the robot classes into memory
require_relative 'workflows/sdrIngestWF/load_robots'

# load the robot-controller into memory
require 'resque'
# REDIS_URL specified in config/environments/{environment}.rb file which was loaded in the boot script
begin
  if defined? REDIS_TIMEOUT
    _server, _namespace = REDIS_URL.split('/', 2)
    _host, _port, _db = _server.split(':')
    _redis = Redis.new(:host => _host, :port => _port, :thread_safe => true, :db => _db, :timeout => REDIS_TIMEOUT.to_f)
    Resque.redis = Redis::Namespace.new(_namespace, :redis => _redis)
  else
    Resque.redis = REDIS_URL
  end
end

require 'active_support/core_ext' # camelcase
require 'robot-controller'

