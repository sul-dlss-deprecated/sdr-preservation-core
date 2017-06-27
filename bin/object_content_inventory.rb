#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'moab/stanford'
include Stanford

module SdrServices
  Config = Confstruct::Configuration.new do
      username  nil
      password nil
      storage_filesystems nil
      rsync_destination_host nil
      rsync_destination_home nil
  end
end

environment = (
  case `hostname -s`.chomp
    when "sdr-services"
      "sdr-services.rb"
    when "sdr-services-test"
      "sdr-services-test.rb"
    else
      'development'
  end
)
require File.join(ENV['HOME'], "sdr-preservation-core/current/config/environments/#{environment}")


#pull the file from the commandline argument and read each line into the druids array
druids = []
druidlist = File.open(ARGV[0])
druidlist.each_line {|line|
  druids.push line.chomp
}

#for each druid in the array, format it, retrieve the file information for the content group, pull out just the signature and file name, and finally out as a csv

druids.each do |druid|
  druid = "druid:#{druid}" unless druid.start_with?('druid')
  content_group = Moab::StorageServices.retrieve_file_group('content',druid)
  content_group.path_hash.each do |file,signature|
    puts "#{druid}, #{file.to_s}, #{signature.md5}, #{signature.size}"
  end
end
