#!/usr/bin/env ruby

require_relative 'environment'
require 'sys/filesystem'

StorageArea = Struct.new(:filesystem, :gb_total, :gb_used, :pct_used, :gb_free, :pct_free)

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
      area.gb_total = (stat.blocks.to_f*stat.block_size.to_f)/gigabye_size
      area.gb_free = (stat.blocks_available.to_f*stat.block_size.to_f)/gigabye_size
      area.gb_used = area.gb_total - area.gb_free
      area.pct_free = sprintf "%2d%",(area.gb_free/area.gb_total)*100
      area.pct_used = sprintf "%2d%",(area.gb_used/area.gb_total)*100
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
        [-18, 8, 7, 8, 7, 8]
    )
    warnings = report_warnings(areas,threshold)
    s << "#{'-'*70}\n#{warnings}\n" unless warnings.empty?
    s
  end

  def report_warnings(areas,threshold=nil)
    threshold ||= 100
    warnings = []
    areas.each do |area|
      if area.gb_free < threshold
        warnings << "Free disk space is below #{threshold} GB for #{area.path}\n"
      end
    end
    warnings
  end

  def exec(args)
    areas = storage_areas
    case args.shift.to_s.upcase
      when 'TERABYTES'
        puts "terabytes = #{areas.inject(0){|result,area| result + area.gb_used/1024}}"
      else
        puts report_context + report_storage_status(areas,args.shift)
    end
  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  ss = StatusStorage.new
  ss.exec(ARGV)
end
