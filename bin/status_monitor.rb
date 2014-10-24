#!/usr/bin/env ruby

require_relative 'environment'
require_relative 'druid_queue'
require_relative 'status_activity'
require_relative 'status_process'
require_relative 'status_storage'
require_relative 'status_workflow'

class StatusMonitor

  def self.syntax()
    puts <<-EOF

    Syntax: bundle-exec.sh status_monitor.rb  {#{WorkflowNames.join('|')}} {report|queue}
    EOF
    self.options
  end

  def self.options()
    puts <<-EOF

    monitor options:

      report [n] = Report overall status and re-run the report every n seconds
      queue      = Check status and enqueue new objects if appropriate

    EOF
  end

  def initialize(workflow)
    @workflow = workflow
    @environment = ENV['ROBOT_ENVIRONMENT']
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

    #TODO: evaluate how resque robots replace and/or modify this method.

    queue_size = @druid_queue.queue_size
    return "queue currently has #{queue_size} items"

    # TODO: do not allow this method to queue items.
    # if queue_size < 1
    #   stopped,why_not = @status_process.stop_process?
    #   unless stopped
    #     workflow_waiting = @status_workflow.workflow_waiting
    #     if workflow_waiting > 0
    #       @druid_queue.enqueue(Sdr::Config.enqueue_max)
    #       queue_size = @druid_queue.queue_size
    #       message = "queued #{queue_size} items"
    #       @status_process.write_process_log(message)
    #       return message
    #     else
    #       return "workflow waiting = 0"
    #     end
    #   else
    #     return why_not
    #   end
    # else
    #   return "queue currently has #{queue_size} items"
    # end
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
    @freegb = areas.select{|area| area.filesystem == StorageServices.storage_roots.last.to_s}.first.free
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
    subject = "#{@workflow} (#{@environment}) - #{subject}"
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
      report = @status_activity.report_error_history(errors,5)
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

  def exec(args)
    case args.shift.to_s.upcase
       when 'REPORT'
         seconds = (args.shift || 10).to_i
         oldrpt = nil
         while true
           monitor_status
           rpt = report_status
           if rpt != oldrpt
             # overwrite previous output (curser top left, clear screen)
             print "\e[f\e[J" unless oldrpt.nil?
             puts rpt
             STDOUT.flush
             oldrpt = rpt
           end
           begin
             timeout(seconds) do
               # exit method if user hits enter key
               gets
               return
             end
           rescue Timeout::Error
             # loop again if specified number of seconds have elapsed
           end
         end

      when 'QUEUE'
        outcome = monitor_queue
        puts outcome unless args.shift.to_s.upcase == 'CRON'
     else
       StatusMonitor.options
     end
  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  workflow = ARGV.shift.to_s
  if WorkflowNames.include?(workflow)
    sm = StatusMonitor.new(workflow)
    sm.exec(ARGV)
  else
    StatusMonitor.syntax
  end
end
