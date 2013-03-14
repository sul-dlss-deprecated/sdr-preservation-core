#!/usr/bin/env ruby

require 'environment'
require 'yaml'

class StatusProcess < Status

  def self.syntax
    puts <<-EOF

    Syntax: bundle-exec.sh status_process.rb {#{WorkflowNames.join('|')}}
        [config {state} {max} {open} {close}]
        [state [RUN|STOP]] = allow processes to start, or cause processes to terminate
        [max {number of processes}] = how many parallel pipelines to run
        [window {open} {close}] = the range of hours in which workflow is operational
        [start?] = return true if ok to start a new pipeline process
        [stop?] = return true if pipeline process should be terminated
        [list]  (what pipeline processes are running and what are they doing)

    EOF
  end

  def initialize(workflow)
    raise "Workflow not recognized: #{workflow}" unless WorkflowNames.include?(workflow)
    @workflow = workflow
    @config_file = AppHome.join("log",@workflow,"current","status","process.config")
    @process_log_file = AppHome.join("log",@workflow,"current","status","process.log")
    @pid_dir = AppHome.join("log",@workflow,"current","processes")
  end

  def read_config
    YAML.load_file(@config_file.to_s)
  end

  def write_config(hash)
    @config_file.open('w'){|f| f.write(hash.to_yaml)}
  end

  def set_config(state,max,open,close)
    config = {:state=>state.upcase,:max=>max.to_i,:open=>open.to_i,:close=>close.to_i}
    write_config(config)
  end

  def set_state(state)
    config = read_config
    config[:state] = state.upcase
    write_config(config)
  end

  def set_max(max)
    config = read_config
    config[:max] = max.to_i
    write_config(config)
  end

  def set_window(open,close)
    config = read_config
    config[:open] = open.to_i
    config[:close] = close.to_i
    write_config(config)
  end

  def start_process?
    config = read_config
    stop,why = stop_process?
    if stop
      return false,why
    elsif process_count < config[:max]
      return true, "RUN"
    else
      return false, "Processes maximum reached"
    end
  end


  def stop_process?
    config = read_config
    if config[:state] != 'RUN'
      return true,"Run state = #{config[:state]}"
    elsif process_count > config[:max]
      return true,"Too many processes running"
    elsif not Time.now.hour.between?(config[:open],config[:close]-1 )
      return true,"Time outside operational window"
    else
      return false,"RUN"
    end
  end

  def write_process_status(pid, druid, step)
    @pid_dir.join(pid.to_s).open('w'){|f| f.puts "#{pid}|#{druid}|#{step}"}
  end

  def delete_pid_file
    pid_file = @pid_dir.join($$.to_s)
    pid_file.delete if  pid_file.exist?
  end

  def write_process_log(message)
    @process_log_file.open('a') {|f| f.printf "%s %8d %s\n", Time.now.strftime('%Y-%m-%d %H:%M:%S'), $$, message }
  end

  def process_count
    process_list.size
  end

  def process_list
    processes = `pgrep -lf robot_runner | grep #{@workflow} | grep -v bundle-exec`
    return [] if processes.nil? or processes.empty?
    process_ids = processes.split("\n").map{|process| process.split(/ /).first}
    process_ids
  end

  def report_process_list()
    stop,why = stop_process?
    s = report_table(
        stop ? "Pipelines closed: #{why}" :
        "#{@workflow} Processes (#{read_config[:max]} max, #{process_count} running)",
        ['pid','druid','workflow step'],
        @pid_dir.children.map{|pidfile| pidfile.read.chomp.split(/\|/)},
        [-10, -11, -25]
    )
    s
  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  workflow = ARGV[0].to_s
  if WorkflowNames.include?(workflow)
    sp = StatusProcess.new(workflow)
    case ARGV[1].to_s.upcase
      when 'CONFIG'
        sp.set_config(*ARGV[2..5]) if ARGV[5]
        puts sp.read_config.inspect
      when 'STATE'
        sp.set_state(ARGV[2]) if ARGV[2]
        puts sp.read_config.inspect
      when 'MAX'
        sp.set_max(ARGV[2]) if ARGV[2]
        puts sp.read_config.inspect
      when 'WINDOW'
        sp.set_window(*ARGV[2..3]) if ARGV[3]
        puts sp.read_config.inspect
      when 'START?'
        start,why_not = sp.start_process?
        puts start.to_s
      when 'STOP?'
        stop,why = sp.stop_process?
        puts stop.to_s
      when 'LIST'
        puts sp.report_context +  sp.report_process_list
      else
        StatusProcess.syntax
    end
  else
    StatusProcess.syntax
  end
end
