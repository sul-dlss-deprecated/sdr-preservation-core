
## and further modified by lyber-core/config.rb

Dor::Config.configure do
  robots do
   workspace nil
  end
  workflow do
   url 'https://workflow-server.stanford.edu/workflow'
  end
  ssl do
   cert_file "#{ROBOT_ROOT}/config/certs/ls-xxx.crt"
   key_file "#{ROBOT_ROOT}/config/certs/ls-xxx.key"
   key_pass 'yyy'
  end
end
#puts Dor::Config.inspect

Sdr::Config.configure do
  ingest_transfer do
    account "userid@dor-host"
    export_dir "/dor/export/"
  end
  logdir File.join(ROBOT_ROOT, 'log')
  dor_export Dir.mktmpdir('export')
  sdr_recovery_home File.join(ROBOT_ROOT,'spec', "temp")
  audit_verbose true
end


# Moab::Config is created in moab-versioning/lib/moab/config.rb
Moab::Config.configure do
  storage_roots File.join(ROBOT_ROOT,'spec','fixtures')
  storage_trunk 'repository'
  deposit_trunk 'deposit'
  path_method :druid
end

# Location of the master controller which handles object queues
REDIS_URL ||= "localhost:6379/resque:development"
REDIS_TIMEOUT = '10' # seconds

Archive::Fixity.default_checksum_types= :sha256
Replication::ArchiveCatalog.root_uri = 'http://localhost:3000'
Replication::Replica.replica_cache_pathname = '/tmp/tape-replication'
