require 'pathname'
require 'time'

DigitalObject = Struct.new(:object_id,:files_restored,:files_failed,:bytes,:transfer_sec,:elapsed_sec)

class RecoveryAnalyzer

  def serialize_data(event_data)
    puts event_data[1].members.join('|')
    puts event_data.map{|row| row.values.join('|')}
  end


  def parse_tsm_restore_log(logfile)
    pathname = Pathname(logfile)
    @lines = pathname.readlines
    @linenum = -1
    event_data = Array.new
    begin
      obj = next_object
      event_data << obj unless obj.nil?
    end until obj.nil?
    event_data
  end

  def next_line(prefix=nil)
    line = nil
    begin
      line = @lines[@linenum += 1]
    end until line.nil? or prefix.nil? or line.start_with?(prefix)
    line
  end

  def next_object
    obj = DigitalObject.new
    obj.object_id = get_object_id('Restoring')
    return nil if obj.object_id.nil?
    obj.files_restored = get_value('Total number of objects restored:')
    obj.files_failed = get_value('Total number of objects failed:')
    obj.bytes = get_bytes('Total number of bytes transferred:')
    obj.transfer_sec = get_secs('Data transfer time:')
    obj.elapsed_sec = get_elapsed_sec('Elapsed processing time:')
    puts obj.inspect
    obj
  end

  def get_object_id(prefix)
    line = next_line(prefix)
    match = /([a-z]{2}\d{3}[a-z]{2}\d{4})/.match(line)
    match ? match.to_s : nil
  end

  def get_value(prefix)
    line = next_line(prefix)
    return nil if line.nil?
    line.sub(prefix,'').strip
  end

  def get_bytes(prefix)
    string_value = get_value(prefix)
    return nil if string_value.nil?
    string_num,units = string_value.split(/\s+/)
    float_value = string_num.to_f
    bytes = case units
      when 'KB'
        float_value * 1024
      when 'MB'
        float_value * 1024 * 1024
      when 'GB'
        float_value * 1024 * 1024 * 1024
      when 'TB'
        float_value * 1024 * 1024 * 1024 * 1024
      else
        string_num
    end
    bytes.to_i
  end

  def get_secs(prefix)
    string_value = get_value(prefix)
    return nil if string_value.nil?
    string_num,units = string_value.split(/\s+/)
    float_value = string_num.to_f
    secs = case units
      when 'sec'
        float_value
      when 'min'
        float_value * 60
      when 'hour'
        float_value * 60 * 60
      else
        string_num
    end
    secs
  end

  def get_elapsed_sec(prefix)
    string_value = get_value(prefix)
    return nil if string_value.nil?
    t = Time.parse(string_value)
    t.hour*3600 + t.min*60 + t.sec
  end

  def puts_string(string)
    puts string
  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  ra = RecoveryAnalyzer.new
  event_data = ra.parse_tsm_restore_log(ARGV.shift.to_s)
  ra.serialize_data(event_data)
end
