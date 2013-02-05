libdir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'boot'
require 'socket'
require 'pathname'
require 'sys/filesystem'
require 'time'

require File.join(File.dirname(__FILE__), "druid_queue")

# You must subclass and provide a get_robots method
class RobotRunner

    # define class instance variables and getter method so that we can inherit from this class
  class << self
    attr_accessor :robot_workflow
  end

  def self.syntax
    puts <<-EOF

    Syntax: env-exec.sh {ingest|migration}_runner.rb ['debug'] ['verify']

    If debug specified, logger will include debug output

    If verify specified, post-robot queries and output file verification will be done

    EOF
  end

  def initialize(flags)
    @robot_workflow = self.class.robot_workflow
    @loglevel = (flags.upcase.include?('DEBUG')) ? 0 : 1
    @verify = (flags.upcase.include?('VERIFY')) ? true : false
    @app_home = ROBOT_ROOT
    @environment = ENV["ROBOT_ENVIRONMENT"]
    @repository_home = Sdr::Config.storage_node
  end

  # loglevel is one of the following integers (default = 1 (INFO))
  #    DEBUG = 0
  #    INFO = 1
  #    WARN = 2
  #    ERROR = 3
  #    FATAL = 4
  def loglevel=(level)
    @loglevel=level
  end

  def verify=(flag)
    @verify = flag
  end

  def process_queue()
    result = {:items=>0,:completed=>0,:error=>0,:fatal=>0}
    druid_queue = DruidQueue.new("#{@app_home}/queue/#{@robot_workflow}", @robot_workflow)
    while true
      run_status = get_run_status
      case run_status
        when "STOP"
          return result
        when "SLEEP"
          sleep 300
        when "RUN"
          druid = druid_queue.next_item
          if druid
            logfile = initialize_logfile(druid)
            status = process_druid(druid, logfile)
            result[:items] += 1
            result[status.to_s] += 1
            logfile = move_logfile(logfile, status)
            if status == 'fatal'
              email_log_file(druid,logfile,status)
              druid_queue.requeue_item(druid,1)
              return result
            end
          else
            sleep 300
          end
        else
          raise "Run status file contains unknown value #{run_status}"
      end
    end
  end

  def get_run_status
    run_status_file = Pathname("#{@app_home}/tmp/run-status")
    run_status = run_status_file.read.chomp.upcase
    run_status
  rescue Exception => e
    raise "Run status file #{run_status_file} could not be read: #{e.message}"
  end

  def initialize_logfile(druid)
    druid_id = druid.split(/:/)[-1]
    time = Time.now
    today = time.strftime('%Y/%m/%d')
    log = "#{@app_home}/log/#{@robot_workflow}/#{today}/active/#{time.strftime('%Y%m%dT%H%M%S')}-#{@robot_workflow}-#{druid_id}"
    logfile = Pathname(log)
    logfile.parent.mkpath
    LyberCore::Log.set_logfile(log)
    LyberCore::Log.set_level(@loglevel || Logger::INFO)
    LyberCore::Log.info "logfile = #{logfile.basename}"
    LyberCore::Log.info "druid = #{druid}"
    LyberCore::Log.info "SDR #{@robot_workflow} run"
    LyberCore::Log.info "environment = #{@environment}"
    LyberCore::Log.info "timestamp = #{time.iso8601}"
    logfile
  end

  # run all robots (in sequence) to process the specified druid
  def process_druid(druid, logfile)
    status = nil
    robots = get_robots
    robots.each do |robot|
      status = run_robot(robot, druid, logfile)
      status = analyze_logfile(logfile) if status == 'error'
      return status if status =='error' or status == 'fatal'
    end
    status
  end

  def get_robots()
    raise "This method should be overriden by a subclass"
  end

  def run_robot(robot, druid, logfile)
    begin
      robot_name = robot[0]
      robot_path = robot[1]
      LyberCore::Log.info "=" * 60
      robot_opts = {:logfile => logfile.to_s, :loglevel => @loglevel, :argv => ['-d', druid]}
      require robot_path
      #    robot_object = eval(robot_name).new(robot_opts)
      # http://www.ruby-forum.com/topic/182803
      robot_class = robot_name.split('::').reduce(Object){|cls, c| cls.const_get(c) }
      robot_object = robot_class.new(robot_opts)
      begin
        robot_status = Dor::WorkflowService.get_workflow_status(
            'sdr', druid, robot_object.workflow_name, robot_object.workflow_step)
      rescue
        robot_status = (robot_name == 'Sdr::MigrationStart') ? 'waiting' : 'unknown'
      end
      case robot_status
        when 'completed'
          LyberCore::Log.info "#{druid} #{robot_name} status = previously completed"
        when 'waiting','error'
          robot_object.start
          sleep 5
          robot_status = Dor::WorkflowService.get_workflow_status(
              'sdr', druid, robot_object.workflow_name, robot_object.workflow_step)
          LyberCore::Log.info "#{druid} #{robot_name} status = #{robot_status}"
          return 'error'if robot_status != "completed"
          if @verify
            return 'error' unless verify_results(robot_object, druid)
          end

        else
          LyberCore::Log.error "#{druid} #{robot_name} unexpected status = #{robot_status}"
          return 'fatal'
      end
    rescue Exception
      LyberCore::Log.error "#{$!.inspect}\n#{$@}"
      return 'fatal'
    end
    return robot_status
  end

  def verify_results(robot_object, druid)
    queries = robot_object.verification_queries(druid)
    queries.each do |query|
      url = query[0]
      expect_code = query[1]
      expect_pattern = query[2]
      LyberCore::Log.info "query_url = #{url.sub(/\/\/.*:.*@/,'//user:pass@')}"
      response = RestClient.get url
      LyberCore::Log.info "response.code = #{response.code}"
      match = response.body =~ expect_pattern ? 'matches:' : 'differs:'
      LyberCore::Log.info "response.body #{match} #{expect_pattern.inspect}"
      if match != 'matches:'
        LyberCore::Log.error "ItemError: Query response does not match expected pattern - #{expect_pattern.inspect}"
        return false
      end
    end
    output_files = robot_object.verification_files(druid)
    output_files.each do |filepath|
      pathname = Pathname(filepath)
      existence = pathname.exist? ? 'found:' : 'missing:'
      LyberCore::Log.info "pathname #{existence} #{pathname.to_s}"
      if existence != 'found:'
        Lybercore::Log.error "ItemError: Expected output file not found - #{pathname}"
        return false
      end
    end
    return true
  end

  def analyze_logfile(logfile)
    log=Pathname(logfile).read
    if log.include?('FATAL')
      return 'fatal'
    elsif log.include?('ItemError')
      return 'error'
    elsif log.include?('ERROR')
      return 'fatal'
    else
      return 'completed'
    end
  end

  def move_logfile(logfile, status)
    log_destination=logfile.parent.parent.join(status,logfile.basename)
    log_destination.parent.mkpath
    log_destination.make_link(logfile)
    logfile.unlink
    log_destination
  end

  def email_log_file(druid, logfile, status)
    `cat #{logfile} | mail -s '#{status} robot status for #{druid}' $USER `
  end

end