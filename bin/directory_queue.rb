require 'pathname'
require 'fileutils'
require 'time'

# A filesystem-based FIFO mechanism for queueing object identifers to mulitple processes
# see http://search.cpan.org/~lcons/Directory-Queue-1.5/lib/Directory/Queue.pm
# or http://dirq.readthedocs.org/en/latest/queuesimple.html#queuesimple-class
# or Python - http://code.google.com/p/directory-queue/
class DirectoryQueue

  def initialize(qdir)
    @qdir = Pathname(qdir).expand_path
    raise "Queue directory not found: #{@qdir}" unless @qdir.exist?
    @delim = ','
  end

  # @param [Pathname, String] filename The location of the file containing a list of item identifers
  #    to be added to the queue
  # @param [Integer] priority The single digit (1 - 9) priority to assign to all the items in the list,
  #   with lower numbers having higher priority
  # @return [Array<Pathname>] the list of pathnames created in the queue
  def add_list_from_file(filename, priority = 2)
    list = Pathname(filename).read.split("\n")
    add_list(list, priority)
  end

  # @param [Array] list The list of unfiltered item identifers to be added to the queue
  # @param [Integer] priority The single digit (1 - 9) priority to assign to all the items in the list,
  #   with lower numbers having higher priority
  # @return [Array<Pathname>] the list of pathnames created in the queue
  def add_list(list, priority = 2)
    list.collect {|item| add_item(item, priority)}
  end

  # @param [String] item The unfiltered item identifer to be added to the queue
  # @param [Integer] priority The single digit (1 - 9) priority to assign to the item,
  #   with lower numbers having higher priority
  # @return [Pathname] the list of pathnames created in the queue
  def add_item(item, priority=1)
    id = input_filter(item)
    existing = find_qfiles(id)
    if existing.empty? or priority < qfile_priority(existing.first)
      qfile = enqueue_item(id, priority)
    else
      qfile = existing.first
      priority = qfile_priority(qfile)
    end
    # remove any duplicates that may be in lower priority queues
    existing.each { |qf| qf.delete if qfile_priority(qf) > priority }
    qfile
  rescue Exception => e
    puts "Item '#{item}' could not be added to the queue"
    puts e.message
  end

  # @param [String] item The unfiltered item identifer to be searched for in the queue
  # @return [Pathname] The location of the queue file representing the object id or nil if not found
  def find_item(item)
    find_qfiles(input_filter(item)).first
  end

  # @param [String] item The unfiltered item identifer to be added to the queue
  # @return [String] If overridden in a subclass, allows the raw identifier to be massaged,
  #   such as by stripping of a prefix or removing characters not compatible with a filename
  def input_filter(item)
    item
  end

  # @param [String] id The (possibly filtered) item identfier that is the last part of the queue filename
  # @return [Array<Pathname>] All filenames matching a pattern that ends with the specified id
  #    normally this should be a single file
  def find_qfiles(id)
    Pathname.glob(@qdir+"*#{@delim}#{id}")
  end

  # @param [Pathname] qfile the filename of the queue file
  # @return [Integer] The priority prefix from the queue file name
  def qfile_priority(qfile)
    qfile.basename.to_s.split(@delim)[0].to_i
  end

  # @param [String] id The (possibly filtered) item identfier that is the last part of the queue filename
  # @param [Integer] priority The single digit (1 - 9) priority to assign to the item,
  #   with lower numbers having higher priority
  # @return [Pathname] Generate a filename composed of the priority,timestamp,id that will sort by name
  def enqueue_item(id, priority)
    filename = "#{priority.to_s}#{@delim}#{timestamp}#{@delim}#{id}"
    qfile = @qdir.join(filename)
    FileUtils.touch(qfile.to_s)
    qfile
  end

  # @return [String] A timestamp consisting of the day-time-milliseconds of the current time
  def timestamp
    t = Time.now
    t.strftime('%Y%m%d-%H%M%S-')+t.to_f.modulo(1).to_s[2..4]
  end

  # @return [String] The reconstructed object identifer of the first item in the queue
  #   advisory file locks are used so that competing processes will be guaranteed a unique item id
  def first_item
    qfiles = @qdir.children
    return nil if qfiles.empty?
    qfile_item(qfiles.first)
  end

  # @return [String] The reconstructed object identifer of the next unlocked item in the queue
  #   advisory file locks are used so that competing processes will be guaranteed a unique item id
  def next_item
    qfiles = @qdir.children
    return nil if qfiles.empty?
    qfiles.each do |qfile|
      next if qfile.basename == Pathname('.DS_Store')
      file = File.new(qfile.to_s)
      if file.flock(File::LOCK_EX | File::LOCK_NB)
        qfile.delete
        file.flock(File::LOCK_UN)
        return qfile_item(qfile)
      end
    end
    nil
  end

  # @param [Pathname] qfile the filename of the queue file
  # @return [String] The reconstructed object identifer of the specified queue file
  def qfile_item(qfile)
    id = qfile.basename.to_s.split(@delim)[-1]
    output_filter(id)
  end

  # @param [String] id The (possibly filtered) item identfier that is the last part of the queue filename
  # @return [String] If overridden in a subclass, allows the raw identifier to be regenerated,
  #    by reversing the logic in the input_filter method
  def output_filter(id)
    id
  end

  # @param [String] item The unfiltered item identifer to be deleted from the queue
  # @return [Integer] Deletes the queue files that match the object identifier
  #    and returns the count of files deleted (normally 1)
  def remove_item(item)
    id = input_filter(item)
    qfiles = find_qfiles(id)
    qfiles.each{|qfile| qfile.delete}
    qfiles.size
  end

  # @param [String] item The unfiltered item identifer to be re-added to the queue
  # @param [Integer] priority The single digit (1 - 9) priority to assign to the item,
  #   with lower numbers having higher priority
  # @return [Pathname]  Deletes the item from the queue, then re-adds it later
  def requeue_item(item, priority=1)
    remove_item(item)
    add_item(item, priority)
  end

end
