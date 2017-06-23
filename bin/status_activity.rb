#!/usr/bin/env ruby

require_relative 'environment'
require_relative 'status_process'
require_relative 'druid_queue'
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
      pipeline   [n] = report recent pipeline starts and stops

    set options:
      druid   {id}         = set the object focus
      version {n}          = set the version focus
      group   {group name} = set the default file group'

    view options:
      druid   {id}           = set the object focus and list the object versions
      version {n}            = set the version focus and list the object version folders
      group   {group name}   = set the default file group and list its files
      deposit                = display folder structure of deposit bag
      log                    = find and display log file content
      file    {name|path}    = find and display file content
      folder  {path}         = display file tree below specified directory (alias is 'tree')
      dor {export|workspace} = display file tree for object on the DOR server
      urls                   = generate URLs for Argo, Dor Fedora, and Workflow server views
    EOF
  end

  def initialize(workflow)
    raise "Workflow not recognized: #{workflow}" unless WorkflowNames.include?(workflow)
    @workflow = workflow
    @current_dir = AppHome.join('log',@workflow,'current')
    @history_file = @current_dir.join("status/ingest-history.txt")
    @latest_ingest = @current_dir.join("status/latest-item.txt")
    @process_log = @current_dir.join("status/process.log")
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
    errors = logfile.each_line.grep(/(ERROR|FATAL)/)
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
      body << ActivityStatus.members.map{|m| detail[m.to_s][i] || "" }
    end
    s = report_table(
        "#{@workflow} Current Queue & Activity",
        ActivityStatus.members,
        body,
        [11, 11, 11, 11]
    )
    s
  end

  def exec_history(subcmd, args)
    case subcmd
      when /^COMP/
        if args.shift.to_s.upcase == 'TAIL'
          system("tail -f #{@history_file}")
        else
          puts report_ingest_history(n=(args.shift || 10).to_i)
        end
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
      when /^PIPE/
        system("cat #{@process_log} | grep -v queued | tail #{(args.shift || 10).to_i}")
    end

  end

  def exec(args)
    cmd = args.shift.to_s.upcase
    subcmd = args.shift.to_s.upcase
    case subcmd
      when /^COMP/,/^ERR/,'REALTIME',/^PIPE/
        exec_history(subcmd, args)
      when 'DRUID','ID'
        druid = args.shift.to_s.downcase
        if druid != ''
          druid = "druid:#{druid}" unless druid.start_with?('druid')
          @storage_object = Moab::StorageServices.find_storage_object(druid, include_deposit=true)
          @storage_version = @storage_object.current_version
          @filegroup = @storage_version.file_category_pathname('metadata')
          @storage_deposit = @storage_object.deposit_bag_pathname
        end
        if @storage_object
          object_home = @storage_object.object_pathname
          if object_home.exist?
            case cmd
              when 'SET'
                puts "Storage: #{@filegroup.to_s}"
              else # list,view
                system "tree -dDL 1 --noreport #{object_home}"
            end
          else
            puts "Storage Not Found: #{object_home}"
          end
          puts "\nDeposit: #{@storage_deposit}" if @storage_deposit.exist?
        else
          puts "You need to specify an object first, using 'set druid'"
        end
      when 'VERSION'
        version = args.shift.to_s
        if version != ''
          begin
            @storage_version = @storage_object.find_object_version(version.to_i)
            @filegroup = @storage_version.file_category_pathname('metadata')
          rescue StandardError => e
            puts e.message
            return
          end
        end
        if @storage_version
          case cmd
            when 'SET'
              puts @filegroup.to_s
            else # list,view
              system "tree -s --noreport #{@storage_version.version_pathname}"
          end
        else
          puts "You need to specify an object first, using 'set druid'"
        end
      when 'GROUP','FILEGROUP','FILETYPE'
        if @storage_version
          group = args.shift.to_s.downcase
          @filegroup = @storage_version.file_category_pathname(group) unless group == ''
          case cmd
            when 'SET'
              puts @filegroup.to_s
            else # list,view
              system "tree -s --noreport #{@filegroup} | more"
          end
        else
          puts "You need to specify an object first, using 'set druid'"
        end
      when 'DEPOSIT'
        system "tree -s --noreport #{@storage_deposit} | more"
      when 'LATEST'
        file_pager(@latest_ingest)
      when 'LOG'
        objid = @storage_object.digital_object_id.split(/:/)[-1]
        %w{active error status completed}.each do |logdir|
          logfile = @current_dir.join(logdir, objid)
          if logfile.exist?
            file_pager(logfile)
            return
          end
        end
        puts "Log file was not found for object: #{objid}"
      when 'FILE'
        filename = args.shift.to_s
        fullpath = Pathname(filename)
        storagepath = @filegroup.join(filename)
        if fullpath.file?
          file_pager(fullpath)
        elsif storagepath.file?
          file_pager(storagepath)
        else
          puts "File was not found : #{filename}"
        end
      when 'TREE','FOLDER'
        dirname = args.shift.to_s
        pathname = Pathname(dirname)
        if pathname.directory?
          system "tree -s #{dirname}"
        else
          puts "Directory was not found : #{dirname}"
        end
      when 'DOR'
        if @storage_object
          dor_url = Sdr::Config.ingest_transfer.account
          druid_tool = DruidTools::Druid.new(@storage_object.digital_object_id,'/dor/workspace')
          area = args.shift.to_s.upcase
          case area
            when 'EXPORT'
              puts "DOR Host: lyberservices#{environment_suffix}"
              system "ssh #{dor_url} 'tree -s --noreport /dor/export/#{druid_tool.id}'"
            when 'WORKSPACE'
              puts "DOR Host: lyberservices#{environment_suffix}"
              system "ssh #{dor_url} 'tree -s --noreport #{druid_tool.path}'"
            else
              puts "Command not recognized: VIEW DOR #{area}"
          end
        else
          puts "You need to specify an object first, using 'set druid'"
        end
      when /^URL/
        if @storage_object
          druid = @storage_object.digital_object_id
          puts "https://argo#{environment_suffix}.stanford.edu/catalog/#{druid}"
          puts "https://sul-dor#{environment_suffix}.stanford.edu/fedora/objects/#{druid}/datastreams/versionMetadata/content"
          puts "https://sul-lyberservices#{environment_suffix}.stanford.edu/workflow/dor/objects/#{druid}/workflows"
        else
          puts "You need to specify an object first, using 'set druid'"
        end
      else
        StatusActivity.options
    end
  end

  def file_pager(pathname)
    if pathname.file?
      if `file -b #{pathname}`.include?('text')
        puts "#{pathname}"
        puts
        chunks = pathname.readlines.each_slice(20).to_a
        if chunks.size == 1
          puts chunks[0]
        else
          puts "*** Displaying 20-line chunks. Press return for next chunk, enter any text to exit ***"
          puts
          chunks.each do |chunk|
            puts chunk
            STDOUT.flush
            input = STDIN.gets.strip.split(/\s+/)
            return unless input.empty?
          end
        end
      else
        puts `file #{pathname}`
      end
    else
      puts "Not a file: #{pathname}"
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

