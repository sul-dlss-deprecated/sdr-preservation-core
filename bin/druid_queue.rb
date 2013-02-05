#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), "directory_queue")
require 'druid-tools'

class DruidQueue < DirectoryQueue

  def self.syntax
    puts <<-EOF
  
    Syntax: env-exec.sh druid_queue.rb {ingest|migration} {druid|filename|query_batch_size}
    
    Mode must be one of:
      * ingest = normal SDR ingest
      * migration = migration from bagit to moab structure
    
    Druid argument must be one of
      * a valid druid
      * name of a file containing a list of druids
      * the next {query_batch_size} druids that are waiting in the workflow

    EOF
  end
  
  def initialize(queue_home, mode)
    raise "Mode not recognized: #{mode}" unless %w{ingest migration}.include?(mode)
    @mode = mode
    super(Pathname(queue_home).join(mode))
  end

  def enqueue(druid_arg)
    if druid_arg =~ /\A(?:druid:)?([a-z]{2})(\d{3})([a-z]{2})(\d{4})\z/
      add_item(druid_arg)
    elsif Pathname(druid_arg).exist?
      add_list_from_file(druid_arg)
    elsif is_integer?(druid_arg)
      add_workflow_waiting(Integer(druid_arg))
    else
      DruidQueue.syntax
    end
  end

  def is_integer?(n)
    !!Integer(n)
  rescue
    false
  end

  def add_workflow_waiting(druid_arg)
    if druid_arg > 1000
      puts "Limiting batch size to 1000 or less"
      batch_size =  1000
    else
      batch_size =  druid_arg
    end
    if @mode =~ /ingest/
      druids = Dor::WorkflowService.get_objects_for_workstep(
          completed='start-ingest', waiting='register-sdr', repository='sdr', workflow='sdrIngestWF')
    elsif @mode =~ /migration/
      druids = Dor::WorkflowService.get_objects_for_workstep(
          completed='migration-start', waiting='migration-register', repository='sdr', workflow='sdrMigrationWF')
    end
    add_list(druids[0..(batch_size-1)])
  end

  # @param [String] item The unfiltered item identifer to be added to the queue
  # @return [String] If overridden in a subclass, allows the raw identifier to be massaged,
  #   such as by stripping of a prefix or removing characters not compatible with a filename
  def input_filter(item)
    dt = DruidTools::Druid.new(item)
    dt.id
  end

  # @param [String] id The (possibly filtered) item identfier that is the last part of the queue filename
  # @return [String] If overridden in a subclass, allows the raw identifier to be regenerated,
  #    by reversing the logic in the input_filter method
  def output_filter(id)
    dt = DruidTools::Druid.new(id)
    dt.druid
  end

end

# This is the equivalent of a java main method
if __FILE__ == $0

  QueueHome = Pathname(__FILE__).expand_path.parent.parent.join("queue").to_s
  Mode = ARGV[0]
  DruidArg = ARGV[1]

  if ARGV.size != 2
    DruidQueue.syntax
  elsif %w{ingest migration}.include?(Mode)
    druid_queue = DruidQueue.new(QueueHome,Mode)
    druid_queue.enqueue(DruidArg)
  else
    DruidQueue.syntax
  end

end
