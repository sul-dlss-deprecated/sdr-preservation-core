require 'sdr/deposit_object'
require 'spec_helper'

describe DepositObject do

  context "SdrDeposit has convenience methods for storage paths" do

    before :all do
      @druid = 'druid:ab123cd4567'
      @bad_identifier = 'druid:aa1234bb123'
      @bad_suri= '89403452'
    end

    specify "SdrDeposit.bag_pathname" do
      object_pathname = DepositObject.new(@druid).bag_pathname(validate=false)
      object_pathname.should == Pathname(Sdr::Config.sdr_deposit_home).
          join(@druid.gsub('druid:',''))
    end

    specify "SdrDeposit.tarfile_pathname" do
      tarfile = DepositObject.new(@druid).tarfile_pathname()
      tarfile.to_s.should == "#{DepositObject.new(@druid).bag_pathname(validate=false)}.tar"
    end


  end

end
