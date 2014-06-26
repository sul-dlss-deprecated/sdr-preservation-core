libdir = File.expand_path('../../../lib')
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
require 'boot'

require 'sdr_ingest/register_sdr'
require 'sdr_ingest/transfer_object'
require 'sdr_ingest/validate_bag'
require 'sdr_ingest/verify_agreement'
require 'sdr_ingest/complete_deposit'
require 'sdr_ingest/ingest_cleanup'
