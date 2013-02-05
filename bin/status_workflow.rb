#!/usr/bin/env ruby

libdir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'boot'
require 'rest-client'
require 'nokogiri'
require 'pathname'
require 'time'
require 'yaml'

WorkflowStep = Struct.new(:name, :waiting, :completed, :error)

class StatusWorkflow

  def initialize(workflow='sdrIngestWF')
    @workflow = workflow
    workflow_config_file = "#{ROBOT_HOME}/config/workflows/#{@workflow}/workflow-config.yaml}"
    workflow_config = YAML.load_file(workflow_config_file)
    @repository = workflow_config['repository']
    process_config_file = "#{ROBOT_HOME}/config/workflows/#{@workflow}/process-config.yaml}"
    @process_config = YAML.load_file(process_config_file)
    @process_steps = Pathname(process_config_file).each_line.grep(/^(.*):$/).map{|line| line.chomp.chop}
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

  def item_step_status(druid, workflow_step)
    Dor::WorkflowService.get_workflow_status(@repository, druid, @workflow, workflow_step)
  end

  def workflow_status_counts
    @process_steps.collect{|step_name| step_counts(step_name)}
  end

  def step_counts(step_name)
    step = WorkflowStep.new()
    step.name = step_name
    %w{waiting completed error}.collect do |status|
      query = step_status_query(step,status)
      step[status] = workflow_count(query)
    end
  end

  def step_status_query(step, status)
    query="#{status}=#{qualify_step(step)}"
    query
  end

  def workflow_count(query)
    subresource = "workflow_queue?#{query}&count-only=true"
    xml = workflow_service[subresource].get
    count = Nokogiri::XML(xml).at_xpath('/objects/@count').value
    count
  end

  def workflow_items(query)
    subresource = "workflow_queue?#{query}"
    xml = workflow_service[subresource].get
    druids = Nokogiri::XML(xml).xpath('//object[@id]').collect{|node| node['id']}
    druids
  end

  def waiting_completed_query(waiting, completed)
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

  def workflow_archive_count
    subresource = "workflow_archive?repository=sdr&workflow=sdrIngestWF&count-only=true"
    xml = workflow_service[subresource].get
    count = Nokogiri::XML(xml).at_xpath('/objects/@count').value
    count
  end

end