require 'pathname'
require 'rubygems'
require 'bundler/setup'
require 'confstruct'
require 'nokogiri'
require_relative 'libdir'
ROBOT_ROOT = Pathname(__dir__).parent.to_s
HOME = ENV['HOME']

# The Dor::Config object is created in dor-services-gem/lib/dor/config.rb
# and initialized with the data in dor-services-gem/config/config_defaults.yml
module Dor
   Config = Confstruct::Configuration.new do
     # see Dor::WorkflowService in dor-services-gem
     robots do
       workspace nil
     end
     workflow do
       url 'https://workflow-server.stanford.edu/workflow'
     end
     ssl do
       cert_file "$HOME/sdr-preservation-core/config/certs/ls-xxx.crt"
       key_file "$HOME/sdr-preservation-core/config/keys/ls-xxx.key"
       key_pass 'yyy'
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
      account "userid@dor-host.stanford.edu"
      export_dir "/dor/export/"
    end
    logdir File.join(ROBOT_ROOT, 'log')
    migration_source "/services-disk/sdr2objects"
    sdr_recovery_home nil
    enqueue_max 10
    audit_verbose false
  end
end


require 'druid-tools'
require 'dor/services/workflow_service'
require 'lyber_core/robot'
require 'lyber_core/log'
require 'moab_stanford'
include Stanford
require 'sdr_replication'

# Load the environment file.
environment = ENV['ROBOT_ENVIRONMENT'] || 'development'
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
        params[:timeout] = 120
        params[:open_timeout] = 120
        if opts[:client_cert_file]
          cert_file = File.read(opts[:client_cert_file])
          params[:ssl_client_cert] = OpenSSL::X509::Certificate.new(cert_file)
        end
        if opts[:client_key_file]
          key_file = File.read(opts[:client_key_file])
          params[:ssl_client_key]  = OpenSSL::PKey::RSA.new(key_file, opts[:client_key_pass])
        end
        @@resource = RestClient::Resource.new(url, params)
      end
    end
  end
end

Dor::WorkflowService.configure Dor::Config.workflow.url

