require_relative 'releasable'
require_relative 'string_case'


class Revision::Info
  DEFAULT_REGEX = /(?<prefix>\s*Info\s+const\s+\S+_REVISION\s*=\s*\{\s*\{\s*)(?<major>\d+)(?<sep1>\s*,\s*)(?<minor>\d+)(?<sep2>\s*,\s*)(?<patch>\d+)(?<postfix>\s*\}\s*\};\s*)/
  DEFAULT_COMMENT_PREFIX = ' *'.freeze
  CHANGELOG_START_TAG = '<BEGIN CHANGELOG>'.freeze
  CHANGELOG_END_TAG = '<END CHANGELOG>'.freeze
  CHANGELOG_START = /.*#{CHANGELOG_START_TAG}.*/
  CHANGELOG_END = /.*#{CHANGELOG_END_TAG}.*/

  attr_accessor :major, :minor, :patch
  attr_accessor :src
  attr_accessor :regex
  attr_accessor :comment_prefix

  def initialize(file, regex: nil, comment_prefix: nil)
    @src=file
    @regex = regex.nil? ? DEFAULT_REGEX : /#{regex}/
    @comment_prefix = comment_prefix || DEFAULT_COMMENT_PREFIX
    matched = false
    File.open(@src).each_line do |line|
      if line =~ @regex
        @major = Regexp.last_match[:major].to_i
        @minor = Regexp.last_match[:minor].to_i
        @patch = Regexp.last_match[:patch].to_i
        matched = true
        break
      end
    end
    raise "Failed to match against #{@regex}" unless matched
  end

  def patch_increment!
    @patch += 1
    self
  end

  def minor_increment!
    @minor += 1
    @patch = 0
    self
  end

  def major_increment!
    @major += 1
    @minor = 0
    @patch = 0
    self
  end

  def new_changelog_placeholder
    placeholder = [@comment_prefix,CHANGELOG_START_TAG,CHANGELOG_END_TAG].join("\n#{@comment_prefix} ")
    # Handle C block comments as a special case for legacy project support
    # Could generalise the comment definition, but feels like unnecessary complexity...
    if @src =~ /\.(c|cpp|h|hpp)$/ && !@comment_prefix =~ /#{Regexp.escape('//')}/
      placeholder = "/**\n${placeholder}\n*/"
    end
    placeholder + "\n"
  end

  def write(output_file_name)

    ref_info = self.class.new(@src, regex: @regex)
    raise 'No revision identifiers incremented' if ref_info.to_s == self.to_s

    entry = get_changelog_entry

    text = File.read(@src)
    text.gsub!(@regex) { |match| "#{$~[:prefix]}#{@major}#{$~[:sep1]}#{@minor}#{$~[:sep2]}#{@patch}#{$~[:postfix]}" }

    #Insert start/end tags if not present
    text += new_changelog_placeholder unless text.match(CHANGELOG_START)

    text.gsub!(CHANGELOG_START) { |match| [match, format_changelog_entry(entry)].join("\n") }

    File.open(output_file_name, 'w') { |f| f.write(text) }
  end

  def write!
    write(@src)
  end

  def to_s
    "#{@major}.#{@minor}.#{@patch}"
  end

  def strip_comment_prefix(line)
    line.gsub(/^\s*#{Regexp.escape(@comment_prefix)}\s?/,'')
  end

  def changelog
    in_changelog = false
    File.open(@src).each_line do |line|
      if in_changelog
        break if line =~ CHANGELOG_END
        yield strip_comment_prefix(line.chomp)
      else
        in_changelog = line =~ CHANGELOG_START
      end
    end
  end

  def last_changelog_entry
    in_entry = false
    lines = []
    changelog do |line|
      if line.length > 0
        in_entry = true
        lines << line
      else
        break if in_entry
      end
    end
    lines
  end

  # Prefixes the entry with an empty line, then prefixes each line with comment chars
  # and converts the line entries to a single string
  def format_changelog_entry(entry_lines)
    entry_lines.unshift('').map { |line| "#{@comment_prefix} #{line}"}.join("\n")
  end

  def get_changelog_entry
    entry_lines = []
    entry_lines << "Version #{self} (#{Time.now.strftime("%d %b %Y")})"
    puts('Changelog entry (one item per line / empty line to end)')
    puts('N.B. Git commit entry will use revision ID and first line of entry')
    while line = $stdin.readline.strip
      break if line.length == 0
      entry_lines << "- #{line}"
    end
    entry_lines
  end

end
