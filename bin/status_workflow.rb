#!/usr/bin/env ruby

require 'environment'
require 'boot'
require 'rest-client'
require 'nokogiri'
require 'yaml'
require 'time'

StepCounts = Struct.new(:workflow_step, :waiting, :error, :completed)

WorkflowSummary = Struct.new(:workflow, :waiting, :error, :recent, :archived)

Robot = Struct.new(:name, :classname, :classpath)

class StatusWorkflow  < Status

  def self.syntax()
    puts <<-EOF

    Syntax: bundle-exec.sh status_workflow.rb {#{WorkflowNames.join('|')}} {detail|summary|waiting}

    result:
      detail returns list of workflow steps with waiting,error,completed counts for each
      summary returns overall workflow's waiting,error,recently completed, and archived counts
      waiting returns the number of items whose first step has "waiting" status
    EOF

  end

  def initialize(workflow)
    @workflow = workflow
    workflow_config_file = "#{ROBOT_ROOT}/config/workflows/#{@workflow}/workflow-config.yaml"
    workflow_config = YAML.load_file(workflow_config_file)
    @repository = workflow_config['repository']
    process_config_file = "#{ROBOT_ROOT}/config/workflows/#{@workflow}/process-config.yaml"
    @process_config = YAML.load_file(process_config_file)
    @process_steps = Pathname(process_config_file).each_line.grep(/^(.*):$/).map{|line| line.chomp.chop}
  end

  def robots
    robots = []
    @process_steps.each do |name|
      robot_props = @process_config[name]
      robots << Robot.new(name, robot_props['classname'], robot_props['classpath'] ) if  robot_props['classname']
    end
    robots
  end

  def item_step_status(druid, workflow_step)
    Dor::WorkflowService.get_workflow_status(@repository, druid, @workflow, workflow_step)
  end

  def workflow_waiting
    waiting_query = compose_query_process_status(@process_steps[1], "waiting")
    request_count(waiting_query)
  end


  def workflow_status_detail
    @process_steps.collect{|process| step_status_counts(process)}
  end

  def workflow_status_summary
    summary = WorkflowSummary.new()
    summary.workflow = @workflow
    waiting_query = compose_query_process_status(@process_steps[1], "waiting")
    summary.waiting = request_count(waiting_query)
    summary.error = 0
    @process_steps[1..-1].each do |process|
      error_query = compose_query_process_status(process, "error")
      summary.error += request_count(error_query)
    end
    completed_query = compose_query_process_status(@process_steps[-1], "completed")
    workflow_completed = request_count(completed_query)
    summary.recent = workflow_completed
    # make sure class instance variables are initialized
    @workflow_completed ||= workflow_completed
    @archive_completed ||= request_archive_count
    # test whether the current count is less than the previously measured count
    if workflow_completed < @workflow_completed
      # if so, then the archiving function must have happened in the meantime
      @archive_completed = request_archive_count
    end
    @workflow_completed = workflow_completed
    summary.archived = @archive_completed
    summary
  end

  def step_status_counts(process)
    step = StepCounts.new()
    step.workflow_step = process
    %w{waiting error completed}.each do |status|
      query = compose_query_process_status(process,status)
      step[status] = request_count(query).to_i
    end
    step
  end

  def compose_query_process_status(process, status)
    query="repository=#{@repository}&workflow=#{@workflow}&#{status}=#{process}"
    query
  end

  def compose_query_waiting_completed(waiting, completed)
    query="waiting=#{qualify_step(waiting)}"
    Array(completed).each{|step| query << "completed=#{qualify_step(step)}"}
    query
  end

  def qualify_step(step)
    current = step.split(/:/,3)
    current.unshift(@workflow) if current.length < 2
    current.unshift(@repository) if current.length < 3
    current.join(':')
  end

  def request_count(query)
    subresource = "workflow_queue?#{query}&count-only=true"
    xml = workflow_service[subresource].get
    count = Nokogiri::XML(xml).at_xpath('/objects/@count').value.to_i
    count
  end

  def request_items(query)
    subresource = "workflow_queue?#{query}"
    xml = workflow_service[subresource].get
    druids = Nokogiri::XML(xml).xpath('//object[@id]').collect{|node| node['id']}
    druids
  end

  def request_archive_count
    subresource = "workflow_archive?repository=#{@repository}&workflow=#{@workflow}&count-only=true"
    xml = workflow_service[subresource].get
    count = Nokogiri::XML(xml).at_xpath('/objects/@count').value.to_i
    count
  rescue
    0
  end

  def workflow_service
    client_cert_resource(Dor::Config.workflow.url)
  end

  def client_cert_resource(url)
    cert=Dor::Config.ssl.cert_file
    key=Dor::Config.ssl.key_file
    pass=Dor::Config.ssl.key_pass
    params = {}
    params[:ssl_client_cert] = OpenSSL::X509::Certificate.new(File.read(cert)) if cert
    params[:ssl_client_key]  = OpenSSL::PKey::RSA.new(File.read(key), pass) if key
    RestClient::Resource.new(url, params,:timeout => 200, :open_timeout => 200 )
  end

  def sdr_service
    client_passwd_resource(Sdr::Config.sdr_storage_url)
  end

  def client_passwd_resource(url)

  end

  def report_status_detail(detail)
    s = report_table(
        "#{@workflow} Step Status",
        StepCounts.members,
        detail.map{|step| step.values},
        [-17, 8, 8, 11]
    )
    s
  end

  def report_status_summary(summary)
    s = report_table(
        "Workflow Database + Archive",
        WorkflowSummary.members,
        [summary.values],
        [-15, 7, 5, 6, 9]
    )
    s
  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  workflow = ARGV[0].to_s
  if WorkflowNames.include?(workflow)
    sw = StatusWorkflow.new(workflow)
    case ARGV[1].to_s .upcase
      when 'DETAIL'
        detail = sw.workflow_status_detail
        puts sw.report_context + sw.report_status_detail(detail)
      when 'SUMMARY'
        summary = sw.workflow_status_summary
        puts sw.report_context + sw.report_status_summary(summary)
      when 'WAITING'
        puts "#{sw.workflow_waiting}\n"
      else
        StatusWorkflow.syntax
    end
  else
    StatusWorkflow.syntax
  end
end