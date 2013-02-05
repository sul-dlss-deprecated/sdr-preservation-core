#!/usr/bin/env ruby

require 'pathname'
require 'time'

DailyStatus = Struct.new(:workflow, :date, :processed, :completed, :error, :fatal)

ErrorDetail = Struct.new(:datetime, :workflow, :druid, :error)

class StatusLogs

  def self.syntax
    puts <<-EOF

    Syntax: env-exec.sh status_logs.rb {ingest|migration} [start-date] [end-date]

    Workflow must be one of:
      * ingest = normal SDR ingest
      * migration = migration from bagit to moab structure

    Start date can be YYYY-MM-DD, 'today', empty (default=today) or n (days back into history)
    If start date is a date spec, then
    End date can be YYYY-MM-DD, empty (default=start date), or n (days forward)

    EOF
  end

  def initialize(workflow_name, logdir=nil)
    raise "Workflow not recognized: #{workflow_name}" unless %w{ingest migration}.include?(workflow_name)
    @workflow_name = workflow_name
    @logdir = Pathname(logdir || Pathname(__FILE__).expand_path.parent.parent.join('log',workflow_name))
  end

  def date_range(time1, time2=nil)
    if time1.nil?
      @start_date = @end_date = Time.now
    elsif is_integer?(time1)
      @end_date = Time.now
      @start_date = @end_date - date_delta(time1)
    elsif time2.nil
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

  def report_title
    "#{`hostname -s`} #{@workflow_name} log report for time period: #{date_label(@start_date)} to #{date_label(@end_date)}"
  end

  def period_counts_output(counts)
    printf "%-10s %-10s %10s %10s %10s %10s\n", *DailyStatus.members
    counts.each do |daily_status|
      printf "%-10s %-10s %10d %10d %10d %10d\n", *daily_status.values
    end
  end

  def period_counts()
    ps = []
    date = @start_date
    while date <= @end_date
      ds = daily_counts(date)
      ps << ds unless ds.nil?
      date += 60*60*24
    end
    ps
  end

  def daily_counts(date)
    date_path = date_label(date)
    date_dir = @logdir.join(date_path)
    return nil unless date_dir.exist?
    ds = DailyStatus.new
    ds.workflow = @workflow_name
    ds.date = date_path
    ds.completed = file_count(date_dir.join('completed'))
    ds.error = file_count(date_dir.join('error'))
    ds.fatal = file_count(date_dir.join('fatal'))
    ds.processed = ds.completed + ds.error + ds.fatal
    ds
  end

  def file_count(pathname)
    return 0 unless pathname.exist?
    pathname.children.size
  end

  def period_errors_output(errors)
    printf "%-16s %-10s %-12s %s \n", *ErrorDetail.members
    errors.each do |error_detail|
      printf "%-16s %-10s %-12s %s \n", *error_detail.values
    end
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

end

# This is the equivalent of a java main method
if __FILE__ == $0
  workflow_name = ARGV[0]
  if %w{ingest migration}.include?(workflow_name)
    status = StatusLogs.new(workflow_name)
    status.date_range(ARGV[1],ARGV[2])
    puts ""
    puts status.report_title
    puts '='*60
    pc = status.period_counts
    status.period_counts_output pc
    puts '-'*60
    pe = status.period_errors
    status.period_errors_output(pe)
    puts ""
  else
    StatusLogs.syntax
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

