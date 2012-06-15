ROBOT_ROOT = File.expand_path(File.join(File.dirname(__FILE__),'..'))
libdir = File.join(ROBOT_ROOT,'lib')
specdir = File.join(ROBOT_ROOT,'spec')
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
$LOAD_PATH.unshift(specdir) unless $LOAD_PATH.include?(specdir)
#puts $LOAD_PATH

require 'confstruct'
# @see https://github.com/mbklein/confstruct

# The Dor::Config object is created in dor-services-gem/lib/dor/config.rb
# and initialized with the data in dor-services-gem/config/config_defaults.yml
module Dor
   Config = Confstruct::Configuration.new do
     # see Dor::WorkflowService in dor-services-gem
     robots do
       workspace nil
     end
     workflow do
       url 'http://lyberservices-xxx.stanford.edu/workflow'
     end
     ssl do
       cert_file '/var/sdr2service/sdr2/config/certs/ls-xxx.crt'
       key_file '/var/sdr2service/sdr2/config/certs/ls-xxx.key'
       key_pass 'lsxxx'
     end
   end
end

#
# This config object is created in moab-versioning/lib/moab/config.rb
# module Moab
#   Config = Confstruct::Configuration.new do
#     repository_home  nil
#     path_method 'druid_tree'
#   end
# end

# Sdr::Config contains the constants that are required within this project
module Sdr
  Config = Confstruct::Configuration.new do
    sedora do
      url  'http://sedora-xxx.stanford.edu/fedora'
      user  'fedoraAdmin'
      password nil
    end
    logdir '/var/sdr2service/log'
    dor_export "lyberadmin@lyberservices-prod.stanford.edu:/dor/export/"
    sdr_deposit_home nil
    storage_node "/services-disk/sdr2objects"
    example_objects "/services-disk/sdr2objects"
  end
end

require 'rubygems'
require 'English'
require 'pathname'
require 'nokogiri'
#require 'logger'

require 'dor/services/workflow_service'
require 'lyber_core/log'
require 'lyber_core/robots/robot'
require 'lyber_core/robots/service_controller'
require 'lyber_core/robots/workflow'
require 'lyber_core/robots/workspace'
require 'lyber_core/robots/work_queue'
require 'lyber_core/robots/work_item'
require 'lyber_core/utils'
require 'lyber_core/exceptions/empty_queue'
require 'lyber_core/exceptions/fatal_error'
require 'lyber_core/exceptions/service_error'
require 'lyber_core/exceptions/item_error'

# Load the environment file based on Environment.  Default to local
if(ENV.include?('ROBOT_ENVIRONMENT'))
  environment = ENV['ROBOT_ENVIRONMENT']
else
  environment = 'test'
end
require File.join(ROBOT_ROOT,"config/environments/#{environment}")


ENABLE_SOLR_UPDATES = false
require 'rake'
require 'active-fedora'
require 'sdr/sedora_configurator'
ActiveFedora.configurator = Sdr::SedoraConfigurator.new
ActiveFedora.init

require 'sdr/sdr_deposit'
require 'sdr/sedora_object'
