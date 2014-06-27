# make sure the lib folder is in the search path, and load the boot.rb file from that path
libdir = File.expand_path('../../../lib')
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
require 'boot'

# load all the robot classes into memory
require_relative 'workflows/sdrIngestWF/load_robots'

# load the robot-controller into memory
require 'resque'
# REDIS_URL specified in config/environments/{environment}.rb file which was loaded in the boot script
Resque.redis = REDIS_URL
require 'active_support/core_ext' # camelcase
require 'robot-controller'

