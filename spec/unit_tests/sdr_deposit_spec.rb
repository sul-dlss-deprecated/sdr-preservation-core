require 'sdr/sdr_deposit'
require 'spec_helper'

describe SdrDeposit do

  context "SdrDeposit has convenience methods for storage paths" do

    before :all do
      @druid = 'druid:ab123cd4567'
      @bad_identifier = 'druid:aa1234bb123'
      @bad_suri= '89403452'
    end

    it "should parse a druid and return a pair tree path prefix" do
      SdrDeposit.druid_tree(@druid).should eql 'druid/ab/123/cd/4567'
      lambda{SdrDeposit.druid_tree(bad_identifier)}.should raise_exception
      lambda{SdrDeposit.druid_tree(bad_suri)}.should raise_exception
    end

    specify "SdrDeposit.bag_pathname" do
      object_pathname = SdrDeposit.bag_pathname(@druid)
      object_pathname.should == Pathname(Sdr::Config.sdr_deposit_home).
          join(SdrDeposit.druid_minus_prefix(@druid))
    end

    specify "SdrDeposit.tarfile_pathname" do
      tarfile = SdrDeposit.tarfile_pathaname(@druid)
      tarfile.should == "#{SdrDeposit.bag_pathname(@druid)}.tar"
    end


  end

end
