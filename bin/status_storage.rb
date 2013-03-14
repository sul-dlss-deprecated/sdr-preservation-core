#!/usr/bin/env ruby

require 'environment'
require 'sys/filesystem'

StorageArea = Struct.new(:filesystem, :gb, :used, :free, :pct)

class StatusStorage < Status

  def self.syntax()
    puts <<-EOF

    Syntax: bundle-exec.sh status_storage.rb [threshold (default=100GB)]

    EOF

  end

  def storage_areas()
    areas = []
    storage_filesystems.each do |stat|
      area = StorageArea.new
      area.filesystem = stat.path
      area.gb = (stat.blocks.to_f*stat.block_size.to_f)/gigabye_size
      area.free = (stat.blocks_available.to_f*stat.block_size.to_f)/gigabye_size
      area.used = area.gb - area.free
      area.pct = sprintf "%2d%",(stat.blocks_available.to_f/stat.blocks.to_f)*100
      areas << area
    end
    areas
  end

  def freegb(filesystem)
    stat = Sys::Filesystem.stat(filesystem)
    (stat.blocks.to_f*stat.block_size.to_f)/gigabye_size
  end

  def storage_filesystems()
    storage_mounts.map{|mount| Sys::Filesystem.stat(mount.mount_point)}
  end

  def storage_mounts()
    Sys::Filesystem.mounts.select{|mount| mount.mount_type.upcase == 'NFS'}
  end

  def gigabye_size
    1024*1024*1024
  end


  def report_storage_status(areas, threshold=nil)
    s = report_table(
        "Storage Areas",
        StorageArea.members,
        areas.map{|area| area.values},
        [-18, 7, 7, 7, 3]
    )
    warnings = report_warnings(areas,threshold)
    s << "#{'-'*70}\n#{warnings}\n" unless warnings.empty?
    s
  end

  def report_warnings(areas,threshold=nil)
    threshold ||= 100
    warnings = []
    areas.each do |area|
      if area.free < threshold
        warnings << "Free disk space is below #{threshold} GB for #{area.path}\n"
      end
    end
    warnings
  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  ss = StatusStorage.new
  areas = ss.storage_areas
  puts ss.report_context + ss.report_storage_status(areas,ARGV[0])
end
