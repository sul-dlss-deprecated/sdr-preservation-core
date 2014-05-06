require File.join(File.dirname(__FILE__), '../libdir')
require 'boot'

module Sdr

  # Contains the shared methods used by all robots that inherit from this object
  class SdrRobot < LyberCore::Robots::Robot

    # Find the location of the deposited object version
    # @param [String] druid The object identifier
    # @return [Pathname] The location of the deposited object version, or raise exception
    def find_deposit_pathname(druid)
      storage_object = StorageServices.find_storage_object(druid,include_deposit=true)
      deposit_pathname = storage_object.deposit_bag_pathname
      return deposit_pathname if deposit_pathname.directory?
      raise "pathname does not exist or is not a directory"
    rescue Exception => e
      raise LyberCore::Exceptions::ItemError.new(druid, "Unable to determine deposit pathname", e)
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
        raise LyberCore::Exceptions::FatalError.new("Failed to transmit request", e)
      end
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

    # @param work_item [LyberCore::Robots::WorkItem] The object being processed
    # @return [Boolean] process the object, then set success or error status
    def process_work_item(work_item)
      begin
        #call overridden method
        process_item(work_item)
        transmit() {work_item.set_success}
      rescue LyberCore::Exceptions::FatalError => fatal_error
        raise fatal_error
      rescue Exception => e
        transmit() {work_item.set_error(e)}
      end
    end


  end

end

