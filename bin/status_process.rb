#!/usr/bin/env ruby

require 'environment'
require 'yaml'

class StatusProcess < Status

  def self.syntax
    puts <<-EOF

    Syntax: bundle-exec.sh status_process.rb {#{WorkflowNames.join('|')}}
    EOF
    self.options
  end

  def self.options
    puts <<-EOF

    process options:

      config {state} {max} {open} {close}
        state [RUN|STOP] = allow processes to start, or cause processes to terminate
        max {number of processes} = how many parallel pipelines to run
        window {open} {close} = the range of hours in which workflow is operational
      start  = run robot pipeline(s) if config settings allow it
      start! = change config state to START and run robot pipeline if otherwise OK
      start? = return true if ok to start a new pipeline process
      stop   = change config state to STOP.  Pipelines will stop after current object
      stop?  = return true if pipeline process should be terminated
      list   = what pipeline processes are running and what are they doing)

    EOF
  end

  def initialize(workflow)
    raise "Workflow not recognized: #{workflow}" unless WorkflowNames.include?(workflow)
    @workflow = workflow
    @environment = ENV['ROBOT_ENVIRONMENT']
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
    return if state.nil?
    config = read_config
    config[:state] = state.upcase
    write_config(config)
  end

  def set_max(max)
    return if max.nil?
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
      return false, "Process maximum reached"
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

  def delete_pid_file(all=false)
    if all
      @pid_dir.children.each{|pid_file| pid_file.delete }
    else
      pid_file = @pid_dir.join($$.to_s)
      pid_file.delete if  pid_file.exist?
    end
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
    list = report_table(
        stop ? "Pipelines closed: #{why}" :
        "#{@workflow} Processes (#{read_config[:max]} max, #{process_count} running)",
        ['pid','druid','workflow step'],
        @pid_dir.children.map{|pidfile| pidfile.read.chomp.split(/\|/)},
        [-10, -11, -25]
    )
    list
  end

  def exec(args)
    case args.shift.to_s.upcase
      when 'CONFIG'
        set_config(*args) if args.size == 4
        puts read_config.inspect
      when 'STATE'
        set_state(args.shift) if args.size == 1
        puts read_config.inspect
      when 'MAX'
        set_max(args.shift) if args.size == 1
        puts read_config.inspect
      when 'WINDOW'
        set_window(*args)  if args.size == 2
        puts read_config.inspect
      when 'START'
        start,why_not = start_process?
        if args.shift.to_s.upcase == 'CRON'
          `echo #{BinHome}/run-pipelines.sh #{@workflow} | at now > /dev/null 2>&1` if start
        elsif start
          `echo #{BinHome}/run-pipelines.sh #{@workflow} | at now`
        else
          puts "Cannot start: #{why_not}."
          puts "Change state or use 'process start!' command." unless why_not == 'Process maximum reached'
        end
      when 'START?'
        start,why_not = start_process?
        puts start.to_s
      when 'START!'
        if args.shift.to_s.upcase == 'CRON'
          set_state('RUN') unless read_config[:state] == 'STOP'
          exec(['start', 'CRON'])
        else
          set_state('RUN')
          exec(['start'])
        end
      when 'STOP'
        stopped,why = stop_process?
        unless stopped
          set_state("STOP")
          stopped,why = stop_process?
        end
        puts why
        firstloop = true
        while true
            # overwrite previous output by moving curser up 7 rows
            print "\e[7A" unless firstloop
            puts report_process_list
            STDOUT.flush
            firstloop = false
            return if process_count == 0
          begin
            timeout(10) do
              # exit method if user hits enter key
              gets
              return
            end
          rescue Timeout::Error
            # loop again if specified number of seconds have elapsed
          end
        end
      when 'STOP?'
        stop,why = stop_process?
        puts stop.to_s
      when 'LIST'
        puts report_context +  report_process_list
      else
        StatusProcess.options
    end
  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  workflow = ARGV.shift.to_s
  if WorkflowNames.include?(workflow)
    sp = StatusProcess.new(workflow)
    sp.exec(ARGV)
  else
    StatusProcess.syntax
  end
end
