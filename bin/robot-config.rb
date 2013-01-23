
libdir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'boot'
require 'socket'
require 'pathname'
#require 'sys/filesystem'

Robot = Struct.new(:name, :path, :queries, :files)
Query = Struct.new(:url, :code, :expectation)
DataFile = Struct.new(:path)

Environment = ENV["ROBOT_ENVIRONMENT"]
StorageUrl = Sdr::Config.sdr_storage_url
WorkflowUrl = Dor::Config.workflow.url
UserPassword = "#{Sdr::Config.sedora.user}:#{Sdr::Config.sedora.password}"
FedoraUrl = Sdr::Config.sedora.url.sub('//',"//#{UserPassword}@")
DepositHome = Sdr::Config.sdr_deposit_home
RepositoryHome = Sdr::Config.storage_node

OneGigabyte=1024*1024*1024

