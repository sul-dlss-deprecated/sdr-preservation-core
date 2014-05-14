require File.join(File.dirname(__FILE__), '../libdir')
require 'boot'
require 'sdr/chained_error'
require 'sdr/item_error'
require 'sdr/fatal_error'

module Sdr

  # Contains the shared methods used by all robots that inherit from this object
  class SdrRobot
    include LyberCore::Robot

    # accessors for class instance variables
    # methods are inherited by subclasses, but @workflow_name and @step_name are not global values
    # @see http://martinfowler.com/bliki/ClassInstanceVariable.html
    class << self
      attr_accessor :workflow_name
      attr_accessor :step_name
    end

    def initialize(workflow_name, step_name, opts = {})
      super('sdr', workflow_name, step_name, opts)
    end

    # Find the location of the deposited object version
    # @param [String] druid The object identifier
    # @return [Pathname] The location of the deposited object version, or raise exception
    def find_deposit_pathname(druid)
      storage_object = StorageServices.find_storage_object(druid,include_deposit=true)
      deposit_pathname = storage_object.deposit_bag_pathname
      return deposit_pathname if deposit_pathname.directory?
      raise "pathname does not exist or is not a directory"
    rescue Exception => e
      raise Sdr::ItemError.new(druid, "Unable to determine deposit pathname", e)
    end

    # Executes a system command in a subprocess.
    # The method will return stdout from the command if execution was successful.
    # The method will raise an exception if if execution fails.
    # The exception's message will contain the explaination of the failure.
    # @param [String] command the command to be executed
    # @return [String] stdout from the command if execution was successful
    def shell_execute(command)
      status, stdout, stderr = systemu(command)
      if (status.exitstatus != 0)
        raise stderr
      end
      return stdout
    rescue
      msg = "Command failed to execute: [#{command}] caused by <STDERR = #{stderr.split($/).join('; ')}>"
      msg << " STDOUT = #{stdout.split($/).join('; ')}" if (stdout && (stdout.length > 0))
      raise msg
    end

    # @param opts [Hash] options (:tries and :interval)
    # @param request [Object] the block of code to execute
    # @return [Boolean] retry request up to :tries times, sleeping :interval seconds after each failed attempt
    def transmit(opts={}, &request)
      tries ||= opts[:tries] || 3
      interval ||= opts[:interval] || 20
      request.call(nil)
    rescue Exception => e
      if (tries -= 1) > 0
        sleep interval
        retry
      else
        raise Sdr::FatalError.new("Failed to transmit request", e)
      end
    end

    def test_success
      return "success"
    end

    def test_failure
      raise "failure"
    end

    def create_workflow_rows(repo, druid, workflow_name, wf_xml, opts = {:create_ds => true})
      transmit(opts) {Dor::WorkflowService.create_workflow(repo, druid, workflow_name, wf_xml, opts )}
    end

    def get_workflow_xml(repo, druid, workflow, opts={})
      transmit(opts) {Dor::WorkflowService.get_workflow_xml(repo, druid, workflow)}
    end

    def get_workflow_status(repo, druid, workflow, step_name, opts={})
      transmit(opts) {Dor::WorkflowService.get_workflow_status(repo, druid, workflow, step_name)}
    end

    def update_workflow_status(repo, druid, workflow, process, status, opts={})
      transmit(opts) {Dor::WorkflowService.update_workflow_status(repo, druid, workflow, process, status)}
    end

    # @param druid [String] The object being processed
    # @return [Boolean] process the object, then set success or error status
    def process_work_item(work_item)
      begin
        #call overridden method
        perform(work_item)
        transmit() {work_item.set_success}
      rescue Sdr::FatalError => fatal_error
        raise fatal_error
      rescue Exception => e
        transmit() {work_item.set_error(e)}
      end
    end


  end

end

