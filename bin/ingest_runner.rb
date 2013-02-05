#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), "robot_runner")

class IngestRunner < RobotRunner

  # Class-level variable
  @robot_workflow = 'ingest'

  def get_robots()
    robots = []
    robots << ["Sdr::RegisterSdr", "sdr_ingest/register_sdr"]
    robots << ["Sdr::TransferObject", "sdr_ingest/transfer_object"]
    robots << ["Sdr::ValidateBag", "sdr_ingest/validate_bag"]
    robots << ["Sdr::PopulateMetadata", "sdr_ingest/populate_metadata"]
    robots << ["Sdr::VerifyAgreement", "sdr_ingest/verify_agreement"]
    robots << ["Sdr::CompleteDeposit", "sdr_ingest/complete_deposit"]
    robots
  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  runner = IngestRunner.new(ARGV)
  runner.process_queue
end
