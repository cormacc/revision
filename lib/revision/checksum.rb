require 'digest'

class Revision::Checksum

  READ_CHUNK_KB = 1024
  FILENAME_EXTENSION = "md5"

  MD5 = {name: "md5", generator: Digest::MD5}
  SHA512 = {name: "sha512", generator: Digest::SHA512}

  attr_reader :root, :filename

  def self.from_file(filepath, filename: nil, type: SHA512)
    raise "File #{filepath} not found" unless File.exist?(filepath)
    filename ||= File.basename(filepath)
    root = File.dirname(filepath)
    stream = File.open(filepath, 'rb')
    new(stream, filename, root: root, type: type)
  end

  def initialize(ioreader, filename, root: nil, type: SHA512)
    root ||= Dir.getwd
    @reader = ioreader
    @root = root
    @filename = filename
    @impl = type
  end

  def calc
    checksum = @impl[:generator].new
    bytes_per_chunk = READ_CHUNK_KB*1024
    while chunk = @reader.read(bytes_per_chunk)
      checksum << chunk
    end
    checksum.hexdigest
  end

  def to_s
    <<~EOT
    #{calc} #{@filename}
    EOT
  end

  def chkfilename
    "#{@filename}.#{@impl[:name]}"
  end

  def write(filepath: nil)
    filepath ||= File.join(@root, chkfilename)
    filename = File.basename(filepath)
    File.open(filepath, "w") { |f| f.write "#{calc} #{filename}" }
    filepath
  end

end
