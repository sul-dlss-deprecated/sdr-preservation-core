#!/usr/bin/env ruby

require 'environment'
require 'druid_queue'
require 'status_activity'
require 'status_process'
require 'status_storage'
require 'status_workflow'

class StatusMonitor

  def self.syntax()
    puts <<-EOF

    Syntax: bundle-exec.sh status_monitor.rb  {#{WorkflowNames.join('|')}} {report|queue}

    report = just check status once and output reports
       options:  loop n  (re-run the report every n seconds )

    queue = check status and enqueue new objects if appropriate

    EOF

  end


  def initialize(workflow)
    @workflow = workflow
    @druid_queue = DruidQueue.new(@workflow)
    @status_activity = StatusActivity.new(@workflow)
    @status_process = StatusProcess.new(@workflow)
    @status_storage = StatusStorage.new
    @status_workflow = StatusWorkflow.new(@workflow)
    @status_home = AppHome.join('log',@workflow,'current','status')
    @storage_report = @status_home.join("storage-filesystems.txt")
    @workflow_report = @status_home.join("workflow-summary.txt")
    @latest_item =  @status_home.join("latest-item.txt")
    @ingest_history =  @status_home.join("ingest-history.txt")
    @error_report = @status_home.join("error-history.txt")
    self.freegb_threshold=100
  end

  def monitor_queue
    if @druid_queue.queue_size < 1
      unless @status_process.stop_process?.first
        workflow_waiting = @status_workflow.workflow_waiting
        if workflow_waiting > 0
          @druid_queue.enqueue(4000)
          queue_size = @druid_queue.queue_size
          message = "Queued #{queue_size} items to #{@workflow}"
          @status_process.write_process_log(message)
          email(message)
        end
      end
    end
  end

  def monitor_status
    monitor_storage
    monitor_workflow
    monitor_errors
  end

  def monitor_storage
    return @freegb if @freegb and (Time.now - @storage_report.mtime) < 300 #seconds
    areas = @status_storage.storage_areas
    report = @status_storage.report_storage_status(areas,@freegb_threshold)
    @storage_report.open('w'){|f| f.write(report)}
    @freegb = areas.select{|area| area.filesystem == Pathname(Sdr::Config.storage_node).parent.to_s}.first.free
    test_freegb(@freegb)
    @freegb
  end

  def test_freegb(freegb)
    if freegb < @freegb_threshold
      email("CRITICAL: Storage space now < #{@freegb_threshold} GB",
            @storage_report) unless @freegb_warning == :critical
      @freegb_warning = :critical
    elsif freegb < @freegb_threshold * 2
      email("WARNING: Storage space now < #{@freegb_threshold*2} GB",
            @storage_report) unless @freegb_warning == :warning
      @freegb_warning = :warning
    end
  end

  def freegb_threshold=(gb)
    @freegb_threshold = gb
    @freegb_warning = nil
  end

  def email(subject, message=nil)
    case message
      when Pathname
        `cat #{message} | mail -s '#{subject}' $USER `
      when String
        `echo '#{message}' | mail -s '#{subject}' $USER `
      else
        `echo '#{subject}' | mail -s '#{subject}' $USER `
    end
  end

  def monitor_workflow
    return @waiting if @waiting and (Time.now - @workflow_report.mtime) < 300 #seconds
    summary = @status_workflow.workflow_status_summary
    @workflow_report.open('w'){|f| f.write(@status_workflow.report_status_summary(summary))}
    @waiting = summary.waiting
  end

  def monitor_errors
    if !@error_report.exist? or Time.now.day != @error_report.mtime.day
      errors = @status_activity.error_history.last(3)
      report = @status_activity.report_error_history(errors)
      @error_report.open('w'){|f| f.write(report)}
    end
  end

  def report_status
    context = Status.new.report_context.split("\n")
    storage_rpt = @storage_report.read.split("\n")
    workflow_rpt = @workflow_report.read.split("\n")
    current_stats = @status_activity.real_time_statistics
    current_rpt = @status_activity.report_realtime_activity(*current_stats).split("\n")
    process_rpt = @status_process.report_process_list.split("\n")
    latest_item = @latest_item.read.split("\n")
    history_rpt = @status_activity.report_ingest_history(3)
    error_rpt = @error_report.read

    left =  storage_rpt + workflow_rpt + current_rpt + process_rpt
    right =  [""] + latest_item

    s = context
    (0...left.size).each do |n|
      s << (sprintf "%-50s  #   %s\n", left[n], right[n] || "")
    end
    s << (sprintf "%s", history_rpt)
    s << (sprintf "%s", error_rpt)
  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  workflow = ARGV[0].to_s
  if WorkflowNames.include?(workflow)
    sm = StatusMonitor.new(workflow)
    case ARGV[1].to_s.upcase
      when 'REPORT'
        while true
          sm.monitor_status
          rpt = sm.report_status
          if ARGV[2].to_s.upcase == 'LOOP'
            puts `clear`
            puts rpt
            STDOUT.flush
            sleep (ARGV[3] ? ARGV[3].to_i : 20)
          else
            puts rpt
            break
          end
        end
      when 'QUEUE'
        sm.monitor_queue
      else
        StatusMonitor.syntax
    end
  else
    StatusMonitor.syntax
  end
end
