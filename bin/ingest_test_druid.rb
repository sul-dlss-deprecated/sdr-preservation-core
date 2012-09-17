#!/usr/bin/env ruby

# run all robots (in sequence) to process the specified druid

libdir = File.expand_path(File.join(File.dirname(__FILE__),'lib'))
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
require 'boot'
require File.join(ROBOT_ROOT,'bin','ingest_test_config.rb')

environment = ENV["ROBOT_ENVIRONMENT"]
time = Time.now

druid = ARGV[0]
unless druid =~ /\A(?:druid:)?([a-z]{2})(\d{3})([a-z]{2})(\d{4})\z/
  puts = 'You must supply a valid druid as the first argument to this program'
  exit
end

logfile = "#{ROBOT_ROOT}/log/#{time.strftime('%Y%m%dT%H%M%S')}-#{druid.split(/:/)[1]}"
LyberCore::Log.set_logfile(logfile)

loglevel = ARGV[1] || Logger::INFO
LyberCore::Log.set_level(loglevel)

LyberCore::Log.info "SDR Ingest Test Run"
LyberCore::Log.info "environment = #{environment}"
LyberCore::Log.info "timestamp = #{time.iso8601}"
LyberCore::Log.info "druid = #{}druid}"


robot_opts = {:logfile => logfile, :loglevel => loglevel, :argv => ['-d', druid]}

fedora_url = "http://#{Sdr::Config.sedora.user}:#{Sdr::Config.sedora.password}@#{Sdr::Config.sedora.url}"
deposit_path = Sdr::Config.sdr_deposit_home
druid.split(/:/)[1] =~ /^([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/
repository_path = File.join( Sdr::Config.storage_node, $1, $2, $3, $4, identifier)


robots.each do |robot|
  LyberCore::Log.info "=" * 60
  robot_object = Sdr::Submodule.const_get(robot.name).new(robot_opts)
  robot_object.start
  sleep 5
  robot_status = Dor::WorkflowService.get_workflow_status('sdr', druid, robot_object.workflow_name, robot_object.workflow_step)
  LyberCore::Log.info "robot status = #{robot_status}"
  robot.queries.each do |query|
    url = query.url.sub(/\{fedora\}/,fedora_url).sub(/\{druid\}/,druid)
    response = RestClient.get url
    success = response.body =~ "#{query.expectation}" ? true : false
    LyberCore::Log.info "query = #{query.url}"
    LyberCore::Log.info "response = #{response.code}, success = #{success.to_s}"
  end
  robot.files.each do |file|
    pathname = Pathname(file.path.sub(/\{druid\}/,druid).sub(/\{deposit\}/,deposit_path).sub(/\{repository_path\}/,repository_path))
    LyberCore::Log.info "pathname #{pathname} exist = #{pathname.exist?}"
  end
  exit if robot_status != "completed"
end


