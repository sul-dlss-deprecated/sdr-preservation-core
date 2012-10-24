#!/usr/bin/env ruby

# run all robots (in sequence) to process the specified druid

libdir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

environment = ENV["ROBOT_ENVIRONMENT"]
time = Time.now

Druid = ARGV[0]
unless Druid =~ /\A(?:druid:)?([a-z]{2})(\d{3})([a-z]{2})(\d{4})\z/
  puts 'You must supply a valid druid as the first argument to this program'
  exit
end

load File.join(File.dirname(__FILE__), 'ingest_test_config.rb')

druid_id = Druid.split(/:/)[1]
logfile = "#{ROBOT_ROOT}/log/#{time.strftime('%Y%m%dT%H%M%S')}-#{druid_id}"
LyberCore::Log.set_logfile(logfile)

loglevel = ARGV[1] || Logger::INFO
LyberCore::Log.set_level(loglevel)

LyberCore::Log.info "SDR Ingest Test Run"
LyberCore::Log.info "environment = #{environment}"
LyberCore::Log.info "timestamp = #{time.iso8601}"
LyberCore::Log.info "druid = #{Druid}"

Robots.each do |robot|
  begin
    LyberCore::Log.info "=" * 60
    robot_opts = {:logfile => logfile, :loglevel => loglevel, :argv => ['-d', Druid]}
    require robot.path
#    robot_object = eval(robot.name).new(robot_opts)
# http://www.ruby-forum.com/topic/182803
    robot_class = robot.name.split('::').reduce(Object){|cls, c| cls.const_get(c) }
    robot_object = robot_class.new(robot_opts)
    robot_status = Dor::WorkflowService.get_workflow_status('sdr', Druid, robot_object.workflow_name, robot_object.workflow_step)
    case robot_status
      when 'completed'
        LyberCore::Log.info "robot status = previously completed"
      else
        robot_object.start
        sleep 5
        robot_status = Dor::WorkflowService.get_workflow_status('sdr', Druid, robot_object.workflow_name, robot_object.workflow_step)
        LyberCore::Log.info "robot status = #{robot_status}"
        robot.queries.each do |query|
          LyberCore::Log.info "query_url = #{query.url}"
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
    end
  rescue Exception
    LyberCore::Log.error "#{$!.inspect}\n#{$@}"
    exit
  end
end


