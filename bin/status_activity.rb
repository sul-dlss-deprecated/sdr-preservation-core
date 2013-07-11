#!/usr/bin/env ruby

require 'environment'
require 'status_process'
require 'druid_queue'
require 'pathname'
require 'time'
require 'timeout'


ActivityStatus = Struct.new(:queue, :active, :completed, :error)

ErrorDetail = Struct.new(:datetime, :druid, :error)

IngestDetail = Struct.new(:date,:time,:pipes,:elapsed,:druid,:version,:cfiles,:cbytes,:mfiles,:mbytes)


class StatusActivity < Status

  def self.syntax
    puts <<-EOF

    Syntax: bundle-exec.sh status_activity.rb {#{WorkflowNames.join('|')}} {history|errors|realtime}
    EOF
    self.options
  end

  def self.options
    puts <<-EOF

    list options:

      completed  [n] = report recent ingest details (default is 10)
      errors     [n] = report error details
      realtime   [n] = report activity, looping every n seconds (default is 10)

    view options:

      log       [id] = find and display log file content using "cat" command
      file    [path] = find and display file content using "cat" command
      tree [id|path] = display folder structure of storage area

    EOF
  end

  def initialize(workflow)
    raise "Workflow not recognized: #{workflow}" unless WorkflowNames.include?(workflow)
    @workflow = workflow
    @current_dir = AppHome.join('log',@workflow,'current')
    @history_file = @current_dir.join("status/ingest-history.txt")
    @druid_queue = DruidQueue.new(@workflow)
    @status_process = StatusProcess.new(@workflow)
  end

  def date_label(time)
    time.strftime('%Y/%m/%d')
  end

  def real_time_summary
    summary = ActivityStatus.new
    summary.queue = @druid_queue.queue_size
    summary.active = @current_dir.join('active').children.size
    summary.completed = @current_dir.join('completed').children.size
    summary.error = @current_dir.join('error').children.size
    summary
  end
  
  def real_time_statistics
    summary = real_time_summary
    detail = ActivityStatus.new
    detail.active = latest_druids('active')
    n = [1,detail.active.size].max
    detail.queue = @druid_queue.top_id(n)
    detail.completed = latest_druids('completed',n)
    detail.error = latest_druids('error',n)
    [summary,detail,n]
  end

  def latest_druids(status,n=nil)
    status_dir = @current_dir.join(status)
    return [] unless status_dir.exist?
    druids = status_dir.children.sort{|a,b| a.mtime <=> b.mtime }.collect{|f| f.basename.to_s}
    return druids unless n
    druids.last(n)
  end

  def error_history()
    errors = []
    error_dir = @current_dir.join('error')
    error_dir.children.each do |logfile|
      ie = item_error(logfile)
      errors << ie unless ie.nil?
    end
    errors.sort{|a,b| a.datetime <=> b.datetime}
  end

  def item_error(logfile)
    ie = ErrorDetail.new
    ie.datetime = logfile.mtime.strftime('%Y-%m-%d %H:%M')
    ie.druid = logfile.basename.to_s
    errors = logfile.each_line.grep(/ERROR/) + logfile.each_line.grep(/FATAL/)
    return nil if errors.empty?
    error_line = errors.last.chomp
    offset = error_line.index(ie.druid) ? error_line.index(ie.druid)+11 : error_line.index("::")+3
    ie.error = error_line[offset..-1]
    ie
  end

  def report_ingest_history(n)
    n ||= 10
    lines = @history_file.readlines
    lines = lines.last(n) if n
    s = report_table(
        "#{@workflow} Completed History",
        IngestDetail.members,
        lines.map{|line| line.chomp.split('|')},
        [-10, -8, 5, 11, -11, 7, 6, 13, 6, 13]
    )
    s
  end

  def report_error_history(errors,n)
    n ||= 10
    s = report_table(
        "#{@workflow} Error History",
        ErrorDetail.members,
        errors.first(n).map{|error| error.values},
        [-16, -11, -77]
    )
    s
  end
  
  def report_realtime_activity(summary,detail,n)
    body = Array.new
    body << summary.values
    n.times do |i|
      body << ActivityStatus.members.map{|m| detail[m][i] || "" }
    end
    s = report_table(
        "#{@workflow} Current Queue & Activity",
        ActivityStatus.members,
        body,
        [11, 11, 11, 11]
    )
    s
  end

  def exec(args)
    command = args.shift.to_s.upcase
    case command
      when /^COMP/
        puts report_ingest_history(n=(args.shift || 10).to_i)
      when /^ERR/
        errors = error_history
        puts report_context + report_error_history(errors, n=(args.shift || 10).to_i)
      when 'REALTIME'
        seconds = (args.shift || 10).to_i
        oldrpt = nil
        while true
          rts = real_time_summary
          rpt = report_realtime_activity(rts,nil,0)
          if rpt != oldrpt
            # overwrite previous output by moving curser up 7 rows
            print "\e[7A" unless oldrpt.nil?
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
      when 'LOG'
        objid = args.shift.to_s.split(/:/)[-1]
        if objid == 'nil'
          system "tail -n +1 #{@current_dir.join('active').to_s}/*"
          return
        elsif objid =~ /^([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/
          %w{active error status completed}.each do |logdir|
            logfile = @current_dir.join(logdir, objid)
            if logfile.exist?
              system "cat #{logfile.to_s}"
              return
            end
          end
        end
        puts "Log file was not found for object: #{objid}"
      when 'FILE'
        filename = args.shift.to_s
        pathname = Pathname(filename)
        if pathname.file?
          system "cat #{pathname.to_s}"
          return
        end
        puts "File was not found : #{filename}"
      when 'TREE'
        dirname = args.shift.to_s
        if dirname =~ /^([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/
          repository = Stanford::StorageRepository.new
          storage_path = repository.storage_object_pathname(dirname)
          system "tree -idf --noreport #{storage_path}"
          return
        else
          pathname = Pathname(dirname)
          if pathname.directory?
            system "tree -s #{dirname}"
            return
          end
        end
        puts "Directory was not found : #{dirname}"
      else
        StatusActivity.options
    end
  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  workflow = ARGV.shift.to_s
  if WorkflowNames.include?(workflow)
    sa = StatusActivity.new(workflow)
    sa.exec(ARGV)
  else
    StatusActivity.syntax
  end

end

