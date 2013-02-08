#!/usr/bin/env ruby

libdir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require File.join(File.dirname(__FILE__), "directory_queue")
require 'druid-tools'

class DruidQueue < DirectoryQueue

  def self.syntax
    puts <<-EOF
  
    Syntax: env-exec.sh druid_queue.rb {ingest|migration} {enqueue|list} {druid|filename|query_batch_size}
    
    Workflow must be one of:
      * ingest = normal SDR ingest
      * migration = migration from bagit to moab structure
    
    Druid argument must be one of
      * a valid druid
      * name of a file containing a list of druids
      * the next {query_batch_size} druids that are waiting in the workflow

    EOF
  end
  
  def initialize(queue_home, workflow)
    raise "Workflow not recognized: #{workflow}" unless %w{ingest migration}.include?(workflow)
    @workflow = workflow
    super(Pathname(queue_home).join(workflow))
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
    require 'boot'
    if @workflow =~ /ingest/
      druids = Dor::WorkflowService.get_objects_for_workstep(
          completed='start-ingest', waiting='register-sdr', repository='sdr', workflow='sdrIngestWF')
    elsif @workflow =~ /migration/
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

  if %w{ingest migration}.include?(ARGV[0].to_s)
    queue_home = Pathname(__FILE__).expand_path.parent.parent.join("queue").to_s
    druid_queue = DruidQueue.new(queue_home,ARGV[0])
    case ARGV[1].to_s.upcase
      when 'ENQUEUE'
        druid_queue.enqueue(ARGV[2])
      when 'LIST'
        puts druid_queue.top_file(n=100)
      else
        DruidQueue.syntax
    end
  else
    DruidQueue.syntax
  end

end
