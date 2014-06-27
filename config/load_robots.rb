libdir = File.expand_path('../../../lib')
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
require 'boot'

require_relative 'workflows/sdrIngestWF/load_robots'

require 'resque'
# RESIS_URL specified in config/environments/{environment}.rb file which was loaded in the boot script
Resque.redis = REDIS_URL
require 'active_support/core_ext' # camelcase
require 'robot-controller'

