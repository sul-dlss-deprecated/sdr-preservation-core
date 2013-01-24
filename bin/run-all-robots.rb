#!/usr/bin/env ruby

if ARGV.size < 2
  puts "syntax: run_all_robots.rb {ingest|migration}[_test] [query|druid|filename] [loglevel]"
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

druids.each do |druid|
  
  druid_id = druid.split(/:/)[-1]

  time = Time.now
  today = time.strftime('%Y/%m/%d')
  logfile = "#{ROBOT_ROOT}/log/#{today}/#{time.strftime('%Y%m%dT%H%M%S')}-#{Mode}-#{druid_id}"
  puts "logfile = #{logfile}"
  Pathname(logfile).parent.mkpath
  
  LyberCore::Log.set_logfile(logfile)
  
  LyberCore::Log.set_level(Loglevel || Logger::INFO)
  
  LyberCore::Log.info "druid = #{druid}"
  LyberCore::Log.info "SDR #{Mode} run"
  LyberCore::Log.info "environment = #{Environment}"
  LyberCore::Log.info "timestamp = #{time.iso8601}"

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

 # run all robots (in sequence) to process the specified druid
  robots = get_robots(druid)
  robots.each do |robot|
    begin
      LyberCore::Log.info "=" * 60
      robot_opts = {:logfile => logfile, :loglevel => Loglevel, :argv => ['-d', druid]}
      require robot.path
      #    robot_object = eval(robot.name).new(robot_opts)
      # http://www.ruby-forum.com/topic/182803
      robot_class = robot.name.split('::').reduce(Object){|cls, c| cls.const_get(c) }
      robot_object = robot_class.new(robot_opts)
      begin
        robot_status = Dor::WorkflowService.get_workflow_status('sdr', druid, robot_object.workflow_name, robot_object.workflow_step)
      rescue
        robot_status = (robot.name == 'Sdr::MigrationStart') ? 'waiting' : 'unknown'
      end
      case robot_status
        when 'completed'
          LyberCore::Log.info "#{druid} #{robot.name} status = previously completed"
        when 'waiting','error'
          robot_object.start
          sleep 5
          robot_status = Dor::WorkflowService.get_workflow_status('sdr', druid, robot_object.workflow_name, robot_object.workflow_step)
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
          exit if robot_status != "completed"
        else
          LyberCore::Log.error "#{druid} #{robot.name} unexpected status = #{robot_status}"
          exit
      end
    rescue Exception
      LyberCore::Log.error "#{$!.inspect}\n#{$@}"
      exit
    end
  end

end



