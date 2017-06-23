#!/usr/bin/env ruby

require_relative 'environment'
require_relative 'status_activity'
require_relative 'status_storage'
require_relative 'status_workflow'
require_relative 'status_monitor'

class Menu

  def self.syntax()
    puts <<-EOF

    Syntax: bundle-exec.sh menu.rb  {#{WorkflowNames.join('|')}}

    EOF

  end

  def initialize(workflow)
    @workflow = workflow
    @status_activity = StatusActivity.new(@workflow)
    @status_storage = StatusStorage.new
    @status_workflow = StatusWorkflow.new(@workflow)
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
      status = current.join('status')
      FileUtils.touch status.join('ingest-history.txt').to_s
    end
  end

  def menu(args=nil)
    if @menu.nil?
      @menu = []
      @menu << 'menu                                = Display this menu'
      @menu << 'storage                             = Report storage filesystem status'
      @menu << 'workflow {detail|summary|waiting}   = Report workflow database status'
      @menu << 'list     {comp..|err..}[n] = Report current or recent robot activity '
      @menu << 'set      {druid|version|group} {id} = Set the object/version/filegroup focus and/or list the object versions'
      @menu << 'view     {druid|version|group} {id} = Set the object/version/filegroup focus and list the child folders/files'
      @menu << 'view     {log|pipeline|urls|dor}    = view object\'s logfile, recent pipeline history, URLs, or DOR files'
      @menu << 'view     file/tree {name|path}      = view specified file or directory structure'
      @menu << 'quit                                = Exit'
    end
    title = "Menu for #{@workflow}:"
    puts "\n#{title}"
    puts '-'*title.size
    @menu.each do |item|
      puts "  #{item}"
    end
  end

  def call(args)
    cmd = args.first.to_s
    case cmd
      when 'list','set','view'
        @status_activity.exec(args)
      else
        args.shift
        case cmd
          when 'storage'
            @status_storage.exec(args)
          when 'workflow'
            @status_workflow.exec(args)
        end
    end
  rescue StandardError => e
    puts e.message
    puts e.backtrace
  end

  def exec(args)
    menu
    while true
      cmd = args.first.to_s
      if ['exit','quit'].include?(cmd)
        return
      elsif ['help','?'].include?(cmd)
        menu
      elsif @menu.collect{|item| item.split(/ /).first}.include?(cmd)
        puts
        call(args)
      elsif not (cmd.nil? or cmd.empty?)
        puts "Command not recognised: #{cmd} #{args.join(' ')}"
        menu
      end
      puts ""
      STDOUT.flush
      system "printf '#{@workflow} (#{ENV['ROBOT_ENVIRONMENT']}) > ' >&2"
      args = STDIN.gets.strip.split(/\s+/)
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
