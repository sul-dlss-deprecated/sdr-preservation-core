
# This script is used to create DOR objects from the data in
# the /dor/test-content directory.  It does the following:
#
# - Finds all the druids from the /dor/test-content directory
# - Removes the objects from Fedora, Solr, and SDR
# - Creates the objects
# - Kicks off assembly for each one
#
# You run the script by:
# - ssh into one of the robot VMs in test
# - scp the attached script to that VM, into a ~/bin path
# - bash$ cd common-accessioning/current/
# - bash$ export SDR_HOST='sdr-host'
# - bash$ export SDR_USER='sdr-user'
# - bash$ kinit <user_with_access_to_sdr>
# - bash$ bundle exec ./bin/console test
# - pry> load "#{ENV['HOME']}/bin/register_objs.rb"
# - pry> WfMuxTester.test


class WfMuxObjSetup
  BAG_DIR =  ENV['DOR_BAG_DIR'] || '/dor/test-content'
  ASSEMBLY_DIR = ENV['DOR_ASSEMBLY_DIR'] || '/dor/assembly'
  TEST_APO = 'druid:fg586rn4119'

  def self.go druid, opts = {}
    setup = WfMuxObjSetup.new(druid, opts)
    setup.setup_assembly
    setup.register_obj
  end

  def initialize druid, opts = {}
    @druid = druid
    @apo = opts.fetch(:apo, TEST_APO)
  end

  def setup_assembly
    assembly_dr = DruidTools::Druid.new @druid, ASSEMBLY_DIR
    md_base = File.join(BAG_DIR, assembly_dr.id, 'data', 'metadata')
    cm_doc = Nokogiri::XML IO.read File.join(md_base, 'contentMetadata.xml')

    # contentMetadata cleanup
    #   remove jp2 file nodes
    jp2_nodes = cm_doc.xpath( '/contentMetadata/resource/file[@mimetype = "image/jp2"]')
    jp2_nodes.each {|n| n.remove}

    # remove size attribute and all children from the tif file node
    tiff_nodes = cm_doc.xpath( '/contentMetadata/resource/file[@mimetype = "image/tiff"]')
    tiff_nodes.each do |tn|
      tn.children.each {|ch| ch.remove}
      tn.remove_attribute 'size'
    end

    # copy modified contentMd to assembly
    assembly_dr.mkdir
    File.open(File.join(assembly_dr.metadata_dir, 'contentMetadata.xml'), 'w') do |f|
      f.write pp_xml cm_doc
    end

    # copy content to base root object's druid tree in assembly area
    FileUtils.cp File.join(md_base, 'descMetadata.xml'), assembly_dr.metadata_dir
    content_base = File.join(BAG_DIR, assembly_dr.id, 'data', 'content')
    content_files = Dir.glob File.join(content_base, '*')
    content_files.each {|f| FileUtils.cp f, assembly_dr.path}
  end

  def register_obj
    params = {
      :pid => @druid,
      :object_type => 'item',
      :content_model => 'image',
      :admin_policy => @apo,
      :label => 'wf-mux-testing',
      :source_id => { :sul => DruidTools::Druid.new(@druid, '').id },
      :tags => ['Project : wf-mux-testing'],
      :rights => 'default'
    }
    Dor::RegistrationService.register_object params
  end

  def pp_xml doc
    Nokogiri::XML(doc.to_xml) { |x| x.noblanks }.to_xml { |config| config.no_declaration }
  end

end

class WfMuxTester
  BAG_DIR =  ENV['DOR_BAG_DIR'] || '/dor/test-content'
  SDR_HOST = ENV['SDR_HOST'] || 'sdr-host'
  SDR_USER = ENV['SDR_USER'] || 'sdr-user'

  def self.test
    druids = Dir.entries BAG_DIR
    druids.reject! {|d| d =~ /^\.\.?$/}.map! {|dr| "druid:#{dr}"}
    tester = WfMuxTester.new druids
    tester.nuke_existing_objs
    tester.clear_sdr
    tester.create_new_objs
    tester.initiate_wf
    puts "Done! #{Time.new.localtime}"
  end

  def initialize druids
    @druids = druids
  end

  def nuke_existing_objs
    @druids.each do |druid|
      begin
        i = Dor::Item.find druid
        if i
            Dor::CleanupService.nuke! druid
            puts "#{druid} nuked"
        end
      rescue ActiveFedora::ObjectNotFoundError => onfe
        puts "Skipping nuke of #{druid}"
      rescue => e
        puts "Unable to nuke #{druid}: #{e.message}"
        puts e.backtrace.join("\n")
      end
    end
  end

  def clear_sdr
    cmd1 = %[echo -e "#{@druids.join('\n')}" > /tmp/f]
    system %(ssh #{SDR_USER}@#{SDR_HOST} '#{cmd1}')
    cmd2 = %(cd ${HOME}/sdr-preservation-core/current; ./bin/purge_object.rb < /tmp/f)
    system %(ssh #{SDR_USER}@#{SDR_HOST} '#{cmd2}')
  end

  def create_new_objs
    @druids.each do |druid|
      begin
        WfMuxObjSetup.go druid
        puts "Created #{druid}"
      rescue => e
        puts "Unable to create #{druid}: #{e.message}"
        puts e.backtrace.join("\n")
      end
    end
  end

  def initiate_wf
    opts = {
      :create_ds => true,
      :lane_id => 'default'
    }
    @druids.each do |druid|
      Dor::WorkflowService.create_workflow('dor', druid, 'assemblyWF', Dor::WorkflowObject.initial_workflow('assemblyWF'), opts)
    end
  end

end


