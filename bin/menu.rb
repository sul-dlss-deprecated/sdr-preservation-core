#!/usr/bin/env ruby

require 'environment'
require 'druid_queue'
require 'status_activity'
require 'status_process'
require 'status_storage'
require 'status_workflow'
require 'status_monitor'

class Menu
  def self.syntax()
    puts <<-EOF

    Syntax: bundle-exec.sh menu.rb  {#{WorkflowNames.join('|')}}

    EOF

  end

  def initialize(workflow)
    @workflow = workflow
    @druid_queue = DruidQueue.new(@workflow)
    @status_activity = StatusActivity.new(@workflow)
    @status_process = StatusProcess.new(@workflow)
    @status_storage = StatusStorage.new
    @status_workflow = StatusWorkflow.new(@workflow)
    @status_monitor =StatusMonitor.new(@workflow)
    @status_home = AppHome.join('log',@workflow,'current','status')
    @storage_report = @status_home.join("storage-filesystems.txt")
    @workflow_report = @status_home.join("workflow-summary.txt")
    @latest_item =  @status_home.join("latest-item.txt")
    @ingest_history =  @status_home.join("ingest-history.txt")
    @error_report = @status_home.join("error-history.txt")
    initialize_log_current
  end

  def initialize_log_current
    current = AppHome.join('log',@workflow,'current')
    unless current.exist?
      current.mkpath
      subdirs=%w{active completed error processes queue status}
      subdirs.each { |subdir| current.join(subdir).mkdir }
      active = current.join('active')
      FileUtils.touch active.join('ingest-history.txt').to_s
      @status_process.set_config('RUN',1,6,22)
    end
  end

  def menu(args=nil)
    if @menu.nil?
      @menu = []
      @menu << 'menu                                = Display this menu'
      @menu << 'storage                             = Report storage filesystem status'
      @menu << 'workflow {detail|summary|waiting}   = Report workflow database status'
      @menu << 'queue {enqueue item(s)|size|list n} = Add to queue or report queue status '
      @menu << 'process {config|pipeline|list}      = Configure, run, or report status of robot pipelines'
      @menu << 'activity {history|errors|realtime}  = Report current or recent robot activity '
      @menu << 'monitor {report [loop n]|queue}     = Report overall status or queue new workflow db items'
      @menu << 'quit                                = Exit'
    end
    title = "Menu for #{@workflow}:"
    puts "\n#{title}"
    puts '-'*title.size
    @menu.each do |item|
      puts "  #{item}"
    end
  end

  def workflow(args)
    @status_workflow.exec(args)
  end

  def queue(args)
    @druid_queue.exec(args)
  end

  def process(args)
    @status_process.exec(args)
  end

  def activity(args)
    @status_activity.exec(args)
  end

  def storage(args)
    @status_storage.exec(args)
  end

  def monitor(args)
    @status_monitor.exec(args)
  end

  def exec(args)
    menu
    while true
      cmd = args.shift.to_s
      if ['exit','quit'].include?(cmd)
        return
      elsif ['help','?'].include?(cmd)
        menu
      elsif @menu.collect{|item| item.split(/ /).first}.include?(cmd)
        send(cmd.to_sym, args)
      elsif not (cmd.nil? or cmd.empty?)
        puts "Command not recognised: #{cmd} #{args.join(' ')}"
        menu
      end
      puts ">"
      STDOUT.flush
      args = gets.strip.split(/\s+/)
    end
  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  workflow = ARGV.shift.to_s
  if WorkflowNames.include?(workflow)
    menu = Menu.new(workflow)
    menu.exec(ARGV)
  else
    Menu.syntax
  end
end
