#!/usr/bin/env ruby

if ARGV.size < 2
  puts "syntax: run_all_robots.rb {ingest|migration}[_test] [query|druid|filename] [loglevel]"
  exit
end

Mode = ARGV[0]
DruidArg = ARGV[1]
Loglevel = ARGV[2]

require File.join(File.dirname(__FILE__), "robot-config.rb")

require File.join(File.dirname(__FILE__), "#{Mode}-config.rb")

if DruidArg == 'query'
  if Mode =~ /ingest/
    druids = Dor::WorkflowService.get_objects_for_workstep(
        completed='start-ingest', waiting='register-sdr', repository='sdr', workflow='sdrIngestWF')
  elsif Mode =~ /migration/
    druids = Dor::WorkflowService.get_objects_for_workstep(
        completed='migration-start', waiting='migration-register', repository='sdr', workflow='sdrMigrationWF')
  end
elsif DruidArg =~ /\A(?:druid:)?([a-z]{2})(\d{3})([a-z]{2})(\d{4})\z/
  druids = [DruidArg]
elsif Pathname(DruidArg).exist?
  druids =  Pathname(DruidArg).read.split("\n")
else
  puts 'You must supply a valid druid (or name of a file containing a list of druids) as the 2nd argument to this program'
  exit
end

  #if Environment == 'production'
    #stat = Sys::Filesystem.stat(RepositoryHome)
    #gigabytes_free = (stat.blocks_available.to_f*stat.block_size.to_f)/OneGigabyte
    #if gigabytes_free < 100
    #  LyberCore::Log.error "Free disk space is below minimum of 100GB"
    #  exit
    #end
    #pct_free = (stat.blocks_available.to_f/stat.blocks.to_f)*100
    #if pct_free < 10
    #  LyberCore::Log.error "Free disk space is below minimum of 10%"
    #  exit
    #end
  #end

def run_robot(robot, druid, logfile)
  begin
    LyberCore::Log.info "=" * 60
    robot_opts = {:logfile => logfile, :loglevel => Loglevel, :argv => ['-d', druid]}
    require robot.path
    #    robot_object = eval(robot.name).new(robot_opts)
    # http://www.ruby-forum.com/topic/182803
    robot_class = robot.name.split('::').reduce(Object){|cls, c| cls.const_get(c) }
    robot_object = robot_class.new(robot_opts)
    begin
      robot_status = Dor::WorkflowService.get_workflow_status(
          'sdr', druid, robot_object.workflow_name, robot_object.workflow_step)
    rescue
      robot_status = (robot.name == 'Sdr::MigrationStart') ? 'waiting' : 'unknown'
    end
    case robot_status
      when 'completed'
        LyberCore::Log.info "#{druid} #{robot.name} status = previously completed"
      when 'waiting','error'
        robot_object.start
        sleep 5
        robot_status = Dor::WorkflowService.get_workflow_status(
            'sdr', druid, robot_object.workflow_name, robot_object.workflow_step)
        LyberCore::Log.info "#{druid} #{robot.name} status = #{robot_status}"
        robot.queries.each do |query|
          LyberCore::Log.info "query_url = #{query.url.sub(UserPassword,'user:pass')}"
          response = RestClient.get query.url
          LyberCore::Log.info "response.code = #{response.code}"
          match = response.body =~ query.expectation ? 'matches:' : 'differs:'
          LyberCore::Log.info "response.body #{match} #{query.expectation.inspect}"
          exit if match != 'matches:'
        end
        robot.files.each do |file|
          pathname = Pathname(file.path)
          existence = pathname.exist? ? 'found:' : 'missing:'
          LyberCore::Log.info "pathname #{existence} #{pathname.to_s}"
          exit if existence != 'found:'
        end
        return 'error'if robot_status != "completed"
      else
        LyberCore::Log.error "#{druid} #{robot.name} unexpected status = #{robot_status}"
        return "fatal error"
    end
  rescue Exception
    LyberCore::Log.error "#{$!.inspect}\n#{$@}"
    return "fatal error"
  end
  return robot_status
end

def initialize_logfile(druid)
  druid_id = druid.split(/:/)[-1]
  time = Time.now
  today = time.strftime('%Y/%m/%d')
  logfile = "#{ROBOT_ROOT}/log/#{today}/#{time.strftime('%Y%m%dT%H%M%S')}-#{Mode}-#{druid_id}"
  puts "logfile = #{logfile}"
  Pathname(logfile).parent.mkpath
  LyberCore::Log.set_logfile(logfile)
  LyberCore::Log.set_level(Loglevel || Logger::INFO)
  LyberCore::Log.info "logfile = #{logfile}"
  LyberCore::Log.info "druid = #{druid}"
  LyberCore::Log.info "SDR #{Mode} run"
  LyberCore::Log.info "environment = #{Environment}"
  LyberCore::Log.info "timestamp = #{time.iso8601}"
  logfile
end

def analyze_logfile(logfile)
  log=Pathname(logfile).read
  if log.include?('ItemError')
    return 'item error'
  elsif log.include?('ERROR')
    return 'fatal error'
  else
    return 'ok'
  end
end

# run all robots (in sequence) to process the specified druid
def process_druid(druid, logfile)
  status = nil
  robots = get_robots(druid)
  robots.each do |robot|
    status = run_robot(robot, druid, logfile)
    status = analyze_logfile(logfile) if status == 'error'
    return status if status.include?('error')
  end
  return status
end

def process_batch(druids, druids_processed, item_errors, fatal_error)
  druids.each do |druid|
    logfile = initialize_logfile(druid)
    status = process_druid(druid, logfile)
    druids_processed << "#{druid}-#{status}"
    item_errors << logfile if status == 'item error'
    fatal_error << logfile if status == 'fatal error'
    return status if status == 'fatal error'
  end
  return 'item errors' unless item_errors.empty?
  return 'completed'
end

druids_processed = []
item_errors = []
fatal_error = []
status = process_batch(druids, druids_processed, item_errors, fatal_error)
`echo '#{druids_processed.join("\n")}' | mail -s '#{druids_processed.size.to_s} druids processed by #{Mode}' $USER `
unless item_errors.empty?
  `echo '#{item_errors.join("\n")}' | mail -s '#{item_errors.size.to_s} item errors found during #{Mode}' $USER `
end
unless fatal_error.empty?
  `cat #{fatal_error[-1]} | mail -s 'fatal error for #{druids_processed[-1]} during #{Mode}' $USER `
end
puts "#{druids_processed.size.to_s} druids processed by #{Mode} with batch status = #{status}"

