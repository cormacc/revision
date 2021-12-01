require 'digest'

class Revision::MD5

  READ_CHUNK_KB = 1024
  FILENAME_EXTENSION = "md5"

  attr_reader :root, :filename

  def self.from_file(filepath, filename: nil)
    raise "File #{filepath} not found" unless File.exist?(filepath)
    filename ||= File.basename(filepath)
    root = File.dirname(filepath)
    stream = File.open(filepath, 'rb')
    new(stream, filename, root: root)
  end

  def initialize(ioreader, filename, root: nil)
    root ||= Dir.getwd
    @reader = ioreader
    @root = root
    @filename = filename
  end

  def calc
    md5 = Digest::MD5.new
    bytes_per_chunk = READ_CHUNK_KB*1024
    while chunk = @reader.read(bytes_per_chunk)
      md5 << chunk
    end
    md5.hexdigest
  end

  def to_s
    <<~EOT
    #{calc} #{@filename}
    EOT
  end

  def md5filename
    "#{@filename}.#{FILENAME_EXTENSION}"
  end

  def write(filepath: nil)
    filepath ||= File.join(@root, md5filename)
    filename = File.basename(filepath)
    File.open(filepath, "w") { |f| f.write "#{calc} #{filename}" }
    filepath
  end

end
