require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'sdr_deposit'

describe SdrDeposit do

  context "SdrDeposit has convenience methods for storage paths" do

    before :all do
      @druid = 'druid:ab123cd4567'
      @bad_identifier = 'druid:aa1234bb123'
      @bad_suri= '89403452'
    end

    it "should parse a druid and return a pair tree path prefix" do
      SdrDeposit.suri_pair_tree(@druid).should eql 'druid/ab/123/cd/4567'
      lambda{SdrDeposit.suri_pair_tree(bad_identifier)}.should raise_exception
      lambda{SdrDeposit.suri_pair_tree(bad_suri)}.should raise_exception
    end

    it "should return a path for the local nfs mounted directory" do
      SdrDeposit.local_bag_parent_dir(@druid).should eql "#{ROBOT_ROOT}/config/environments/../../sdr2_example_objects/druid/ab/123/cd/4567"
    end

    it "should return a path for remote (ssh-accessed) directory" do
      SdrDeposit.remote_bag_parent_dir(@druid).should eql "/tmp/druid/ab/123/cd/4567"
    end

  end

end
