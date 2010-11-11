#require File.expand_path(File.dirname(__FILE__) + '/../boot')
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'lyber_core'
require 'sdrIngest/verify_agreement'

describe SdrIngest::VerifyAgreement do 
    context "initial state" do
      before :all do
        ENV['ROBOT_ENVIRONMENT'] = 'sdr-services-test'
        @robot = SdrIngest::VerifyAgreement.new()
      end
  
      it "inherits behavior from LyberCore::Robots::Robot" do
        @robot.should be_kind_of(LyberCore::Robots::Robot)
        @robot.class.superclass.should eql(LyberCore::Robots::Robot)
      end
  
      it "knows its workflow name" do
        @robot.workflow_name.should eql("sdrIngestWF")
      end
  
      it "knows its workflow-step" do
        @robot.workflow_step.should eql("verify-agreement")
      end
  
      it "has a workflow" do
        @robot.workflow.should be_kind_of(LyberCore::Robots::Workflow)
      end
    
      it "should have a logfile assigned" do
        LyberCore::Log.logfile.should eql('/tmp/verify-agreement.log')
      
      end
    
      it "should have a log level assigned" do
        LyberCore::Log.level.should eql(Logger::INFO) 
      end
    
      it "should be able to connect to DOR workflow" do
        pending
        @robot.can_talk_to_workflow_server?.should eql(true)
      
      end
    
      it "returns a valid value for env" do
        @robot.env.should eql('dev')
        #puts @robot.env
      
      end
    
      it "should load the config file for ROBOT_ENVIRONMENT" do
          ENV['ROBOT_ENVIRONMENT'] = 'sdr-services-test'
          puts ENV['ROBOT_ENVIRONMENT']
          Object.send(:remove_const, :DOR_URI)
          robot = SdrIngest::VerifyAgreement.new()
          puts robot.env
          
          DOR_URI.should eql('http://dor-test.stanford.edu/dor')
          WORKFLOW_URI.should eql('http://lyberservices-test.stanford.edu/workflow')
          puts DOR_URI
      end
        
        # @robot = SdrIngest::VerifyAgreement.new()
        # @env = ENV['ROBOT_ENVIRONMENT']
        # if (@env == "dev")
        #   DOR_URI = 'http://dor-test.stanford.edu/dor'
        #   WORKFLOW_URI = 'http://lyberservices-test.stanford.edu/workflow'
        # end
        #                  
      
    
    # it "should raise an error if it cannot get a druid value" do
    #       FakeWeb.allow_net_connect = false
    #         FakeWeb.register_uri(:get, %r|lyberservices-test\.stanford\.edu/|, 
    #           :body => "",
    #           :status => ["500", "Error encountered"])
    #       
    #       lambda{ DorService.get_datastream(druid, ds_id) }.should raise_exception(/Encountered unknown error/)
    #       
    #     end
      
    
  end
end
