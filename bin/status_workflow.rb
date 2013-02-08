#!/usr/bin/env ruby

libdir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'rubygems'
require 'bundler/setup'
require 'boot'
require 'rest-client'
require 'nokogiri'
require 'yaml'
require 'time'

StatusCounts = Struct.new(:process, :waiting, :error, :completed, :archived)

class StatusWorkflow

  def self.syntax()
    puts <<-EOF

    Syntax: env-exec.sh status_workflow.rb {ingest|migration} {detail|summary}

    EOF

  end

  def initialize(workflow='sdrIngestWF')
    @workflow = workflow
    workflow_config_file = "#{ROBOT_ROOT}/config/workflows/#{@workflow}/workflow-config.yaml"
    workflow_config = YAML.load_file(workflow_config_file)
    @repository = workflow_config['repository']
    process_config_file = "#{ROBOT_ROOT}/config/workflows/#{@workflow}/process-config.yaml"
    @process_config = YAML.load_file(process_config_file)
    @process_steps = Pathname(process_config_file).each_line.grep(/^(.*):$/).map{|line| line.chomp.chop}
  end

  def item_step_status(druid, workflow_step)
    Dor::WorkflowService.get_workflow_status(@repository, druid, @workflow, workflow_step)
  end

  def workflow_status_detail
    @process_steps.collect{|process| step_status_counts(process)}
  end

  def workflow_status_summary
    summary = StatusCounts.new()
    summary.process = @workflow
    waiting_query = compose_query_process_status(@process_steps[1], "waiting")
    summary.waiting = request_count(waiting_query).to_i
    completed_query = compose_query_process_status(@process_steps[-1], "completed")
    summary.completed = request_count(completed_query).to_i
    summary.error = 0
    @process_steps[1..-1].each do |process|
      error_query = compose_query_process_status(process, "error")
      summary.error += request_count(error_query).to_i
    end
    summary.archived = request_archive_count
    summary
  end

  def step_status_counts(process)
    step = StatusCounts.new()
    step.process = process
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
    count = Nokogiri::XML(xml).at_xpath('/objects/@count').value
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
    count = Nokogiri::XML(xml).at_xpath('/objects/@count').value
    count
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
    RestClient::Resource.new(url, params)
  end

  def sdr_service
    client_passwd_resource(Sdr::Config.sdr_storage_url)
  end

  def client_passwd_resource(url)

  end

  def report_title(mode)
    environment = ENV["ROBOT_ENVIRONMENT"].capitalize
    title = "#{environment} Workflow Status #{mode} for #{@workflow} on #{`hostname -s`.chomp} as of #{Time.now.strftime('%Y/%m/%d')}\n"
    title << '='*(title.size) + "\n"
    title
  end

  def output_status_detail_counts(status_count_array)
    s = String.new
    s << (sprintf "%-20s %10s %10s %10s\n", *StatusCounts.members[0..-2])
    s << (sprintf "%-20s %10s %10s %10s\n", '-'*20, '-'*10, '-'*10, '-'*10)
    status_count_array.each do |step|
      s << (sprintf "%-20s %10d %10d %10d\n", *step.values)
    end
    s
  end

  def output_status_summary_counts(status_counts)
    s = String.new
    s << (sprintf "%-20s %10s %10s %10s %10s\n", *StatusCounts.members)
    s << (sprintf "%-20s %10s %10s %10s %10s\n", '-'*20, '-'*10, '-'*10, '-'*10, '-'*10)
    s << (sprintf "%-20s %10d %10d %10d %10d\n", *status_counts)
    s
  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  workflow = ARGV[0].to_s.downcase
  if %w{ingest migration}.include?(workflow)
    sw = StatusWorkflow.new(workflow)
    case ARGV[2].to_s .upcase
      when 'DETAIL'
        detail = sw.workflow_status_detail
        puts ""
        puts sw.report_title('detail')
        puts sw.output_status_detail_counts(detail)
        puts ""
      when 'SUMMARY'
        summary = sw.workflow_status_summary
        puts ""
        puts sw.report_title('summary')
        puts sw.output_status_summary_counts(summary)
        puts ""
      else
        StatusWorkflow.syntax
    end
  end
end