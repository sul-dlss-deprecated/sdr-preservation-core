ROBOT_ROOT = File.expand_path(File.join(File.dirname(__FILE__),'..'))
libdir = File.join(ROBOT_ROOT,'lib')
specdir = File.join(ROBOT_ROOT,'spec')
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
$LOAD_PATH.unshift(specdir) unless $LOAD_PATH.include?(specdir)
#puts $LOAD_PATH

require 'rubygems'
require 'bundler/setup'
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
       url 'https://lyberservices-xxx.stanford.edu/workflow'
     end
     ssl do
       cert_file '/var/sdr2service/sdr2/config/certs/ls-xxx.crt'
       key_file '/var/sdr2service/sdr2/config/certs/ls-xxx.key'
       key_pass 'lsxxx'
     end
   end
end

#
# The Moab::Config object is created in moab-versioning/lib/moab/config.rb
# module Moab
#   Config = Confstruct::Configuration.new do
#     storage_roots nil
#     storage_trunk nil
#     deposit_trunk nil
#     path_method 'druid_tree'
#   end
# end

# Sdr::Config contains the constants that are required within this project
module Sdr
  Config = Confstruct::Configuration.new do
    ingest_transfer do
      account "lyberadmin@sul-lyberservices-dev.stanford.edu"
      export_dir "/dor/export/"
    end
    logdir File.join(ROBOT_ROOT, 'log')
    migration_source "/services-disk/sdr2objects"
    sdr_recovery_home nil
    enqueue_max 10
    audit_verbose false
  end
end

require 'rubygems'
require 'English'
require 'pathname'
require 'nokogiri'
#require 'logger'

require 'druid-tools'
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

require 'moab_stanford'
include Stanford

# Load the environment file based on Environment.  Default to local
environment = case ENV["ROBOT_ENVIRONMENT"]
  when 'test'
    "sdr-services-test.rb"
  when 'prod', 'production'
    "sdr-services.rb"
  else
    "development"
end
require File.join(ROBOT_ROOT,"config/environments/#{environment}")

require 'sdr/sdr_robot'

module Dor
  module WorkflowService
    class << self
      # @param [String] url points to the workflow service
      # @param [Hash] opts optional params
      # @option opts [String] :client_cert_file path to an SSL client certificate
      # @option opts [String] :client_key_file path to an SSL key file
      # @option opts [String] :client_key_pass password for the key file
      def configure(url, opts={})
        params = {}
        params[:ssl_client_cert] = OpenSSL::X509::Certificate.new(File.read(opts[:client_cert_file])) if opts[:client_cert_file]
        params[:ssl_client_key]  = OpenSSL::PKey::RSA.new(File.read(opts[:client_key_file]), opts[:client_key_pass]) if opts[:client_key_file]
        params[:timeout] = 120
        params[:open_timeout] = 120
        @@resource = RestClient::Resource.new(url, params)
      end
    end
  end
end

Dor::WorkflowService.configure Dor::Config.workflow.url

