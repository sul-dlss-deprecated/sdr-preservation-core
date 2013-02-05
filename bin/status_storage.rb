#!/usr/bin/env ruby

libdir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'sys/filesystem'

StorageArea = Struct.new(:path, :gb, :used, :free, :pctfree)

class StatusStorage

  def self.syntax()
    puts <<-EOF

    Syntax: env-exec.sh status_storage.rb

    EOF

  end

  def report_title()
    "#{`hostname -s`.chomp} storage area status as of #{Time.now.strftime('%Y/%m/%d')}"
  end


  def storage_status_output(areas)
    printf "%-20s %10s %10s %10s %10s\n", *StorageArea.members
    areas.each do |area|
      printf "%-20s %10.0f %10.0f %10.0f %9.1sf%%\n", *area.values
    end
  end

  def storage_areas()
    areas = []
    storage_filesystems.each do |stat|
      area = StorageArea.new
      area.path = stat.path
      area.gb = (stat.blocks.to_f*stat.block_size.to_f)/gigabye_size
      area.free = (stat.blocks_available.to_f*stat.block_size.to_f)/gigabye_size
      area.used = area.gb - area.free
      area.pctfree = (stat.blocks_available.to_f/stat.blocks.to_f)*100
      areas << area
    end
    areas
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

  def warnings(areas)
    warnings = []
    areas.each do |area|
      if area.free < 100
        warnings << "Free disk space is below 100GB for #{area.path}"
      end
      if area.pctfree < 10
        warnings << "Percent free space is below 10% for #{area.path}"
      end
    end
    warnings
  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  status = StatusStorage.new
  puts ""
  puts status.report_title
  puts '='*70
  areas = status.storage_areas
  status.storage_status_output(areas)
  warnings = status.warnings(areas)
  if ! warnings.empty?
    puts '-'*70
    puts warnings
  end
  puts ""
end
