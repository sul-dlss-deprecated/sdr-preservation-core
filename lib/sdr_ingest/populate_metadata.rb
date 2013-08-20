require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'

module Sdr

  # A robot for adding core datastreams to the Fedora object using metadata files from the bagit object.
  class PopulateMetadata < SdrRobot
    
    # define class instance variables and getter method so that we can inherit from this class
    @workflow_name = 'sdrIngestWF'
    @workflow_step = 'populate-metadata'
    class << self
      attr_accessor :workflow_name
      attr_accessor :workflow_step
    end

    # set workflow name, step name, log location, log severity level
    def initialize(opts = {})
      super(self.class.workflow_name, self.class.workflow_step, opts)
    end

    # @param work_item [LyberCore::Robots::WorkItem] The item to be processed
    # @return [void] process an object from the queue through this robot
    #   Overrides LyberCore::Robots::Robot.process_item method.
    #   See LyberCore::Robots::Robot#process_queue
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      druid = work_item.druid
      populate_metadata(druid)
    end

    # @param druid [String] The object identifier
    # @return [SedoraObject] Add the core metadata datastreams to the Fedora object
    def populate_metadata(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter fill_datastreams")
      bag_pathname = DepositObject.new(druid).bag_pathname()
      sedora_object = Sdr::SedoraObject.find(druid)
      set_datastream_content(sedora_object, bag_pathname, 'identityMetadata')
      set_datastream_content(sedora_object, bag_pathname, 'versionMetadata')
      set_datastream_content(sedora_object, bag_pathname, 'provenanceMetadata')
      set_datastream_content(sedora_object, bag_pathname, 'relationshipMetadata')
      sedora_object.save
      sedora_object
    rescue ActiveFedora::ObjectNotFoundError => e
      raise LyberCore::Exceptions::FatalError.new("Cannot find object #{druid}",e)
    rescue  Exception => e
      raise LyberCore::Exceptions::FatalError.new("Cannot process item #{druid}",e)
    end

    # @param sedora_object [SedoraObject] The Fedora object to which datatream content is to be saved
    # @param bag_pathname [Pathname] The location of the BagIt bag containing the object data files
    # @param dsid [String] The datastream identifier, which is also the basename of the XML data file
    # @return [void] Perform the following steps:
    #   - Determine the metadata files full path in the bagit object,
    #   - determine if the metadata file exists, and if so
    #   - copy the content of the metadata file to the datastream.
    # @raise [LyberCore::Exceptions::FatalError] if we can't find the file
    def set_datastream_content(sedora_object, bag_pathname, dsid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter set_datastream_content for #{dsid}")
      md_pathname = bag_pathname.join('data/metadata',"#{dsid}.xml")
      if md_pathname.file?
        sedora_object.datastreams[dsid].content = md_pathname.read
      end
    rescue Exception => e
      raise LyberCore::Exceptions::FatalError.new("Cannot add #{dsid} datastream for #{sedora_object.pid}",e)
    end

    def verification_queries(druid)
      user_password = "#{Sdr::Config.sedora.user}:#{Sdr::Config.sedora.password}"
      fedora_url = Sdr::Config.sedora.url.sub('//',"//#{user_password}@")
      queries = []
      queries << [
          "#{fedora_url}/objects/#{druid}/datastreams?format=xml", 200,
          /relationshipMetadata/ ]
      queries
    end

    def verification_files(druid)
      files = []
      files
    end

  end
end

# This is the equivalent of a java main method
if __FILE__ == $0
    dm_robot = Sdr::PopulateMetadata.new()
    dm_robot.start
end
