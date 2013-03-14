#!/usr/bin/env ruby

require 'environment'
require 'status_process'
require 'druid_queue'
require 'pathname'
require 'time'


ActivityStatus = Struct.new(:queue, :active, :completed, :error)

ErrorDetail = Struct.new(:datetime, :druid, :error)

IngestDetail = Struct.new(:date,:time,:pipes,:elapsed,:druid,:version,:cfiles,:cbytes,:mfiles,:mbytes)


class StatusActivity < Status

  def self.syntax
    puts <<-EOF

    Syntax: bundle-exec.sh status_activity.rb {#{WorkflowNames.join('|')}} {history|errors|realtime}

    Report mode must be one of
      * history = recent ingest details
      * errors = error details
      * realtime = what is happening right now

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
    error_line = errors.first.chomp
    offset = error_line.index(ie.druid)+11 || error_line.index("::")+3
    ie.error = error_line[offset..-1]
    ie
  end

  def report_ingest_history(n=nil)
    n ||= 100
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

  def report_error_history(errors)
    s = report_table(
        "#{@workflow} Error History",
        ErrorDetail.members,
        errors.map{|error| error.values},
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

end

# This is the equivalent of a java main method
if __FILE__ == $0
  workflow = ARGV[0].to_s
  if WorkflowNames.include?(workflow)
    sa = StatusActivity.new(workflow)
    case ARGV[1].to_s.upcase
      when 'HISTORY'
        puts sa.report_ingest_history(30)
      when 'ERRORS'
        errors = sa.error_history
        puts sa.report_context + sa.report_error_history(errors)
      when 'REALTIME'
        rts = sa.real_time_statistics
        while true
          if ARGV[2].to_s.upcase == 'LOOP'
            print `clear`
            puts sa.report_context + sa.report_realtime_activity(*rts)
            STDOUT.flush
            sleep (ARGV[3] ? ARGV[3].to_i : 20)
          else
            puts rpt
            break
          end
        end
      else
        StatusActivity.syntax
    end
  else
    StatusActivity.syntax
  end

end


#[sdr2service@sdr-services 01]$ grep ^ERROR */error/* | grep -v SystemExit
#error/zn813dy5100:ERROR [2013-01-24 14:43:49] (4417)  :: #<LyberCore::Exceptions::ItemError: druid:zn813dy5100 - Item error; caused by #<NoMethodError: undefined method `size' for nil:NilClass>>
#error/fs553nc0117:ERROR [2013-01-24 16:07:36] (19599)  :: #<LyberCore::Exceptions::ItemError: druid:fs553nc0117 - Item error; caused by #<RuntimeError: Inconsistent size for Thesis.pdf: 7883829 != 7883189>>
#error/sy486tp5223:ERROR [2013-01-24 20:46:55] (22287)  :: #<LyberCore::Exceptions::ItemError: druid:sy486tp5223 - Item error; caused by #<RuntimeError: Inconsistent size for 0-AMadsen-DissFinal-eSubmission.pdf: 12504148 != 10256526>>
#error/ct692vv3660:ERROR [2013-01-25 05:04:32] (12129)  :: #<LyberCore::Exceptions::ItemError: druid:ct692vv3660 - Item error; caused by #<RuntimeError: Inconsistent size for OpLvlAgrmt_ETDs_v01.docx: 27995 != 28062>>
#error/zf098jx2047:ERROR [2013-01-25 06:54:41] (16134)  :: #<LyberCore::Exceptions::ItemError: druid:zf098jx2047 - Item error; caused by #<RuntimeError: Inconsistent size for Vermylen Dissertation (Registrar).pdf: 16219976 != 16228184>>
#error/kn816bg5418:ERROR [2013-01-25 13:10:34] (26810)  :: #<LyberCore::Exceptions::ItemError: druid:kn816bg5418 - Item error; caused by #<RuntimeError: Inconsistent size for Aamir Thesis v71 without copyright and signature page.pdf: 4480500 != 6617220>>
#error/yp464xx6754:ERROR [2013-01-25 13:57:37] (26810)  :: #<LyberCore::Exceptions::ItemError: druid:yp464xx6754 - Item error; caused by #<RuntimeError: Inconsistent size for thesis.pdf: 529516 != 528438>>
#error/fq899hc0553:ERROR [2013-01-25 14:17:58] (26810)  :: #<LyberCore::Exceptions::ItemError: druid:fq899hc0553 - Item error; caused by #<RuntimeError: Inconsistent size for Leyen_Dissertation_8_21_2011_final.pdf: 8224069 != 8282209>>

