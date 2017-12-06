require_relative 'releasable'
require_relative 'string_case'

class Revision::Info
  REVISION_INFO_FILE_SUFFIX = "Revision.c"
  SOURCE_FILE_PATH = "src"
  REV_REGEX = /(\s*Info\s+const\s+\S+_REVISION\s*=\s*\{\s*\{\s*)(\d+)(\s*,\s*)(\d+)(\s*,\s*)(\d+)(\s*\}\s*\};\s*)/
  REV_MAJOR_MATCH_INDEX = 2
  REV_MINOR_MATCH_INDEX = 4
  REV_PATCH_MATCH_INDEX = 6
  attr_accessor :major
  attr_accessor :minor
  attr_accessor :patch
  attr_accessor :module_info

  def get_path()
    File.join(@module_info.path, SOURCE_FILE_PATH, "#{@module_info.name.capitalize}#{REVISION_INFO_FILE_SUFFIX}")
  end

  def initialize(releasable)
    @module_info = releasable
    puts("Loading revision info from #{get_path}")
    load_from_file
    puts("... loaded revision #{self}")
  end

  def patch_increment!
    @patch = @patch+1
    self
  end

  def minor_increment!
    @minor = @minor+1
    @patch = 0
    self
  end

  def major_increment!
    @major = @major+1
    @minor = 0
    @patch = 0
    self
  end

  def write_to_file(output_file_name = temporary_output_file_name)
    output_file = File.new(output_file_name,"w")
    in_revision_struct = false
    File.open(get_path).each_line do |line|
      line.gsub!(REV_REGEX, "\\1#{@major}\\3#{@minor}\\5#{@patch}\\7")
      output_file.puts(line)
      add_changelog_entry(output_file) if line =~ /<<BEGIN CHANGELOG>>/
    end
    output_file.close
  end

  def write!
    write_to_file
    FileUtils.mv(temporary_output_file_name, get_path)
  end

  def to_s
    "#{@major}.#{@minor}.#{@patch}"
  end

  def changelog
    in_changelog = false
    File.open(get_path).each_line do |line|
      if in_changelog
        break if line =~ /<<END CHANGELOG>>/
        yield line.gsub(/^\s\*\s?/,"")
      else
        in_changelog = line =~ /<<BEGIN CHANGELOG>>/
      end
    end
  end


  private

  def temporary_output_file_name
    "#{get_path}.new"
  end

  def add_changelog_entry(output_file)
    output_file.puts(" *")
    output_file.puts(" * Version #{self} (#{Time.now.strftime("%d %b %Y")})")
    # output_file.puts(" * - CHANGES HERE")
    puts("Changelog entry (one item per line / empty line to end):")
    while line = $stdin.readline.strip
      break if line.length == 0
      output_file.puts(" * - #{line}")
    end
  end

  def load_from_file
    # in_revision_struct = false
    File.open(get_path).each_line do |line|
      if line =~ REV_REGEX
        # puts("Matched #{Regexp.last_match[0]}")
        @major = Regexp.last_match[REV_MAJOR_MATCH_INDEX].to_i
        @minor = Regexp.last_match[REV_MINOR_MATCH_INDEX].to_i
        @patch = Regexp.last_match[REV_PATCH_MATCH_INDEX].to_i
        break
      end
    end
  end

end
