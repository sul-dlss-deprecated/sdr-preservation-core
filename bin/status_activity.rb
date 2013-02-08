#!/usr/bin/env ruby

require 'pathname'
require 'time'
require File.join(File.dirname(__FILE__), "druid_queue")


ActivityStatus = Struct.new(:workflow, :datetime, :process, :queue, :active, :completed, :error, :fatal)

ErrorDetail = Struct.new(:datetime, :workflow, :druid, :error)


class StatusActivity

  def self.syntax
    puts <<-EOF

    Syntax: env-exec.sh status_activity.rb {ingest|migration} {realtime|history|errors} [start-date] [end-date]

    Workflow must be one of:
      * ingest = normal SDR ingest
      * migration = migration from bagit to moab structure

    Report mode must be one of
      * realtime = what is happening right now
      * history = log history for the specified date range
      * errors = error details for the specified date range

    Start date can be YYYY-MM-DD, 'today', empty (default=today) or n (how many days of history to show)
    If start date is a date spec, then
    End date can be YYYY-MM-DD, empty (default=start date), or n (days of history to show)

    EOF
  end

  def initialize(workflow, logdir=nil)
    raise "Workflow not recognized: #{workflow}" unless %w{ingest migration}.include?(workflow)
    @workflow = workflow
    @logdir = Pathname(logdir || Pathname(__FILE__).expand_path.parent.parent.join('log',workflow))
    @app_home = ENV["APP_HOME"]
    @druid_queue = DruidQueue.new("#{@app_home}/queue", @workflow)
    date_range('today')
  end

  def date_range(time1, time2=nil)
    if time1.nil?
      @start_date = @end_date = Time.now
    elsif is_integer?(time1)
      @end_date = Time.now
      @start_date = @end_date - date_delta(time1)
    elsif time2.nil?
      @start_date = @end_date = Time.parse(time1)
    elsif is_integer?(time2)
      @start_date = Time.parse(time1)
      @end_date = @start_date + date_delta(time2)
    else
      @start_date = Time.parse(time1)
      @end_date = Time.parse(time2)
      if @end_date < @start_date
        @start_date = Time.parse(time2)
        @end_date = Time.parse(time1)
      end
    end
    [@start_date,@end_date]
  end

  def is_integer?(n)
    !!Integer(n)
  rescue
    false
  end

  def date_delta(days)
    day_delta = days.to_i.abs
    day_delta -= 1 if day_delta > 0
    day_delta*24*60*60
  end

  def date_label(time)
    time.strftime('%Y/%m/%d')
  end

  def period_statistics()
    ps = []
    date = @start_date
    while date <= @end_date
      ds = daily_statistics(date)
      ps << ds unless ds.nil?
      date += 60*60*24
    end
    ps
  end

  def daily_statistics(date)
    date_path = date_label(date)
    date_dir = @logdir.join(date_path)
    return nil unless date_dir.exist?
    daily = ActivityStatus.new
    daily.workflow = @workflow
    daily.datetime = date_path
    daily.completed = file_count(date_dir.join('completed'))
    daily.error = file_count(date_dir.join('error'))
    daily.fatal = file_count(date_dir.join('fatal'))
    daily.active = daily.completed + daily.error + daily.fatal
    daily
  end

  def real_time_summary(date)
    date_path = date_label(date)
    date_dir = @logdir.join(date_path)
    summary = ActivityStatus.new
    summary.workflow = @workflow
    summary.datetime = date.strftime('%H:%M:%S')
    summary.process = processes_running.size
    summary.queue = @druid_queue.queue_size
    summary.active = file_count(date_dir.join('active'))
    summary.completed = file_count(date_dir.join('completed'))
    summary.error = file_count(date_dir.join('error'))
    summary.fatal = file_count(date_dir.join('fatal'))
    summary
  end
  
  def real_time_statistics
    date = Time.now
    summary = real_time_summary(date)
    detail = ActivityStatus.new
    detail.workflow = []
    detail.datetime = []
    detail.process = processes_running
    detail.active = active_druids
    n = [detail.process.size,detail.active.size].max
    detail.queue = @druid_queue.top_id(n)
    detail.completed = latest_druids('completed',n)
    detail.error = latest_druids('error',n)
    detail.fatal = latest_druids('fatal',n)
    [summary,detail,n]
  end

  def output_real_time_statistics(summary,detail,n)
    s = String.new
    s << (sprintf "%-10s %-8s %-7s %11s %11s %11s %11s %11s\n", *ActivityStatus.members )
    s << (sprintf "%-10s %-8s %-7s %11s %11s %11s %11s %11s\n", '-'*10, '-'*8, '-'*7, '-'*11, '-'*11, '-'*11, '-'*11, '-'*11)
    s << (sprintf "%-10s %-8s %-7s %11d %11d %11d %11d %11d\n", *summary.values)
    s << (sprintf "%-10s %-8s %-7s %11s %11s %11s %11s %11s\n", '-'*10, '-'*8, '-'*7, '-'*11, '-'*11, '-'*11, '-'*11, '-'*11)
    n.times do |i|
      values = ActivityStatus.members.map{|m| detail[m][i]||"" }
      s << (sprintf "%-10s %-8s %-7s %11s %11s %11s %11s %11s\n", *values )
    end
    s
  end

  def processes_running
    processes = `pgrep -lf #{@workflow}_runner | grep ruby | grep -v pgrep`
    return [] if processes.nil? or processes.empty?
    process_ids = processes.split("\n").map{|process| process.split(/ /).first}
    process_ids
  end

  def active_druids
    date = Time.now
    date_path = date_label(date)
    active_dir = @logdir.join(date_path,'active')
    return [] unless active_dir.exist?
    filenames = active_dir.children.sort.collect{|f| f.basename.to_s}
    druids = filenames.map{|n| n.split("-").last}
    druids
  end

  def latest_druids(status,n)
    date = Time.now
    date_path = date_label(date)
    status_dir = @logdir.join(date_path,status)
    return [] unless status_dir.exist?
    filenames = status_dir.children.sort.last(n).to_a.collect{|f| f.basename.to_s}
    druids = filenames.map{|name| name.split("-").last}
    druids
  end

  def file_count(pathname)
    return 0 unless pathname.exist?
    pathname.children.size
  end

  def period_errors()
    pe = []
    date = @start_date
    while date <= @end_date
      de = daily_errors(date)
      pe.concat de unless de.empty?
      date += 60*60*24
    end
    pe
  end

  def daily_errors(date)
    de = []
    ['error','fatal'].each do |error_type|
      error_dir = @logdir.join(date_label(date),error_type)
      next unless error_dir.exist?
      error_dir.children.each do |logfile|
        ie = item_error(logfile, error_type)
        de << ie unless ie.nil?
      end
    end
    de.sort
  end

  def item_error(logfile, error_type)
    ie = ErrorDetail.new
    ie.datetime, ie.workflow, ie.druid = logfile.basename.to_s.split(/-/)
    errors =
      case error_type
        when 'error'
          logfile.each_line.grep(/ERROR/)
        when 'fatal'
          logfile.each_line.grep(/FATAL/)
      end
    return nil if errors.empty?
    error_line = errors.first.chomp
    offset = error_line.index("::")+3
    ie.error = error_line[offset..-1]
    ie
  end
  
  def log_history_report_title()
    environment = ENV["ROBOT_ENVIRONMENT"].capitalize
    title = "#{environment} Log History for #{@workflow} on #{`hostname -s`.chomp} for time period: #{date_label(@start_date)} to #{date_label(@end_date)}\n"
    title << '='*(title.size) + "\n"
    title
  end

  def real_time_report_title()
    environment = ENV["ROBOT_ENVIRONMENT"].capitalize
    title = "#{environment} Real Time Status for #{@workflow} on #{`hostname -s`.chomp} for #{date_label(@start_date)}\n"
    title << '='*(title.size) + "\n"
    title
  end

  def period_output(statistics)
    columns = [0,1,4,5,6,7]
    headers = columns.map{|i| ActivityStatus.members[i].to_s}
    s = String.new
    s << (sprintf "%-10s %-10s %10s %10s %10s %10s\n", *headers)
    s << (sprintf "%-10s %-10s %10s %10s %10s %10s\n", '-'*10, '-'*10, '-'*10, '-'*10, '-'*10, '-'*10)
    statistics.each do |daily_status|
      values = columns.map{|i| daily_status.values[i]}
      s << (sprintf "%-10s %-10s %10d %10d %10d %10d\n", *values)
    end
    s
  end

  def period_errors_output(errors)
    s = String.new
    s << (sprintf "%-16s %-10s %-12s %s \n", *ErrorDetail.members)
    s << (sprintf "%16s %10s %12s %s\n", '-'*16, '-'*10, '-'*12, '-'*50)
    errors.each do |error_detail|
      s << (sprintf "%-16s %-10s %-12s %s \n", *error_detail.values)
    end
    s
  end


end

# This is the equivalent of a java main method
if __FILE__ == $0
  workflow = ARGV[0].to_s.downcase
  if %w{ingest migration}.include?(workflow)
    sa = StatusActivity.new(workflow)
    case ARGV[1].to_s.upcase
      when 'HISTORY'
        sa.date_range(ARGV[2],ARGV[3])
        puts ""
        puts sa.log_history_report_title
        pc = sa.period_statistics
        puts sa.period_output(pc)
        puts ""
      when 'ERRORS'
        sa.date_range(ARGV[2],ARGV[3])
        pe = sa.period_errors
        puts ""
        puts sa.period_errors_output(pe)
        puts ""
      when 'REALTIME'
        puts ""
        puts sa.real_time_report_title
        while true
          rts = sa.real_time_statistics
          print  "\e[H\e[2J"
          puts ""
          puts sa.output_real_time_statistics(*rts)
          sleep 20
        end

      else
        StatusActivity.syntax
    end
  else
    StatusActivity.syntax
  end

end


#[sdr2service@sdr-services 01]$ grep ^ERROR */error/* | grep -v SystemExit
#24/error/20130124T144329-migration-zn813dy5100:ERROR [2013-01-24 14:43:49] (4417)  :: #<LyberCore::Exceptions::ItemError: druid:zn813dy5100 - Item error; caused by #<NoMethodError: undefined method `size' for nil:NilClass>>
#24/error/20130124T160723-migration-fs553nc0117:ERROR [2013-01-24 16:07:36] (19599)  :: #<LyberCore::Exceptions::ItemError: druid:fs553nc0117 - Item error; caused by #<RuntimeError: Inconsistent size for Thesis.pdf: 7883829 != 7883189>>
#24/error/20130124T204640-migration-sy486tp5223:ERROR [2013-01-24 20:46:55] (22287)  :: #<LyberCore::Exceptions::ItemError: druid:sy486tp5223 - Item error; caused by #<RuntimeError: Inconsistent size for 0-AMadsen-DissFinal-eSubmission.pdf: 12504148 != 10256526>>
#25/error/20130125T050421-migration-ct692vv3660:ERROR [2013-01-25 05:04:32] (12129)  :: #<LyberCore::Exceptions::ItemError: druid:ct692vv3660 - Item error; caused by #<RuntimeError: Inconsistent size for OpLvlAgrmt_ETDs_v01.docx: 27995 != 28062>>
#25/error/20130125T065424-migration-zf098jx2047:ERROR [2013-01-25 06:54:41] (16134)  :: #<LyberCore::Exceptions::ItemError: druid:zf098jx2047 - Item error; caused by #<RuntimeError: Inconsistent size for Vermylen Dissertation (Registrar).pdf: 16219976 != 16228184>>
#25/error/20130125T131019-migration-kn816bg5418:ERROR [2013-01-25 13:10:34] (26810)  :: #<LyberCore::Exceptions::ItemError: druid:kn816bg5418 - Item error; caused by #<RuntimeError: Inconsistent size for Aamir Thesis v71 without copyright and signature page.pdf: 4480500 != 6617220>>
#25/error/20130125T135726-migration-yp464xx6754:ERROR [2013-01-25 13:57:37] (26810)  :: #<LyberCore::Exceptions::ItemError: druid:yp464xx6754 - Item error; caused by #<RuntimeError: Inconsistent size for thesis.pdf: 529516 != 528438>>
#25/error/20130125T141744-migration-fq899hc0553:ERROR [2013-01-25 14:17:58] (26810)  :: #<LyberCore::Exceptions::ItemError: druid:fq899hc0553 - Item error; caused by #<RuntimeError: Inconsistent size for Leyen_Dissertation_8_21_2011_final.pdf: 8224069 != 8282209>>

