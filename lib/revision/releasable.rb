require 'pathname'
require 'yaml'
require 'zip'

module Revision

  class Releasable

    BUILD_DIR_BASE_NAME = "dist"
    BUILD_CONFIGURATION_DEFAULT = "default"
    BUILD_TARGET_DEFAULT = "production"
    # RELATIVE_PATH_TO_BOOTLOADER = File.join("..","bootloader")
    RELATIVE_PATH_TO_BOOTLOADER = "bootloader"

    CONFIG_FILE_NAME = 'releasables.yaml'.freeze

    attr_reader :root, :id, :revision, :build_steps, :artefacts

    # Load a file in yaml format containing one or more releasable definitions
    # @param root [String] An optional root directory argument
    # @return [Hash] Contents of the yaml file
    def self.load_definitions(root: nil)
      root ||= Dir.getwd
      config_file = File.join(root, CONFIG_FILE_NAME)
      raise Errors::NoDefinition.new(root) unless File.exist?(config_file)
      puts "Loading releasable definitions from #{config_file} ..."
      YAML.load_file(config_file)
    end

    # Instantiate the Releasables defined in releasables.yaml
    def self.from_folder(root = Dir.getwd)
      config = load_definitions(:root=>root)

      releasables = {}
      config[:releasables].each do |config_entry|
        if config_entry[:folder]
          #Load entries from a nested releasable definition file
          releasables = releasables.merge(from_folder(File.join(root, config_entry[:folder])))
        else
          r = new(root: root, config: config_entry)
          releasables[r.id] = r
        end
      end
      releasables
    end

    def initialize(root: nil, config: {})

      root ||= Dir.getwd
      @root = Pathname.new(root).realpath
      @id = config[:id] || File.basename(@root)
      @revision = Info.new(File.join(@root,config[:revision][:file]), regex: config[:revision][:regex], comment_prefix: config[:revision][:comment_prefix])
      @build_steps = config[:build_steps]
      @artefacts = config[:artefacts]
      @artefacts.each { |a| a[:dest] ||= a[:src] }
    end

    def to_s
      <<~EOT
      #{@id} v#{@revision} @ #{@root}

        Build pipeline:
        - #{@build_steps.join("\n  - ")}

        Build artefacts:
        #{artefacts.map{ |a| "  - #{a[:src]} => #{a[:dest]}" }.join("\n")}
      EOT
    end

    def build
      puts "Executing #{@build_steps.length} build steps..."
      Dir.chdir(@root) do @build_steps.each_with_index do |step, index|
          puts "... (#{index+1}/#{@build_steps.length}) #{step}"
          system(step)
          puts "WARNING: build step #{index}: #{step} exit status #{$?.exitstatus}" unless $?.exitstatus.zero?
        end
      end
    end

    def archive_name
      "#{@id}_v#{@revision}.zip"
    end

    def changelog_name
      "#{@id}_revision_history_v#{@revision}.txt"
    end

    def archive
      puts "Packaging #{@artefacts.length} build artefacts as #{archive_name}..."
      if File.exist?(archive_name)
        puts "... deleting existing archive"
        File.delete(archive_name)
      end
      Zip::File.open(archive_name, Zip::File::CREATE) do |zipfile|
        @artefacts.each_with_index do |a, index|
          dest = a[:dest].gsub(/<REV>/, @revision.to_s)
          puts "... (#{index+1}/#{@artefacts.length}) #{a[:src]} => #{dest}"
          zipfile.add(dest, File.join(@root, a[:src]))
        end
        puts "... embedding revision history as #{changelog_name} "
        zipfile.get_output_stream(changelog_name) { |os| output_changelog(os)}
      end
    end

    def output_changelog(output_stream)
      output_stream.puts "Revision history for #{@id} version #{@revision}"
      output_stream.puts ""
      @revision.changelog {|line| output_stream.puts(line)}
    end


    # DEPRECATED BELOW THIS LINE
    def get_build_path
      File.join(@path,BUILD_DIR_BASE_NAME,@configuration,@target)
    end

    def get_image_path
      if @unified_image
        File.join(get_build_path(),"#{@name}.#{@target}.unified.hex")
      else
        File.join(get_build_path(),"#{@name}.#{@target}.hex")
      end
    end

    def is_bootloadable
      # File.exist?(File.join(@path, RELATIVE_PATH_TO_BOOTLOADER))
      puts("Testing #{File.join(Dir.getwd, RELATIVE_PATH_TO_BOOTLOADER)}")
      File.exist?(File.join(Dir.getwd, RELATIVE_PATH_TO_BOOTLOADER))
    end

    def get_bootloader_info
      fail "No bootloader associated with this module!" unless is_bootloadable()
      #fixme: This will only work if cwd = module root
      self.class.new(name: RELATIVE_PATH_TO_BOOTLOADER,unified_image: true)
    end
  end

end
