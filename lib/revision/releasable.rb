require 'pathname'
require 'yaml'
require 'zip'
require 'git'

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
      Dir.chdir(@root) do
        @build_steps.each_with_index do |step, index|
          puts "... (#{index+1}/#{@build_steps.length}) #{step}"
          system(step)
          puts "WARNING: build step #{index}: #{step} exit status #{$?.exitstatus}" unless $?.exitstatus.zero?
        end
      end
    end

    def tag
      Dir.chdir(@root) do
        #Insert a blank line between the revision header and release notes, as per git commit best practice
        commit_message = @revision.last_changelog_entry.insert(1,"\n")
        g = Git.init
        g.commit_all(commit_message)
        g.add_tag("v#{revision}")
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
          src = a[:src].gsub(/<REV>/, @revision.to_s)
          dest = a[:dest].gsub(/<REV>/, @revision.to_s)
          puts "... (#{index+1}/#{@artefacts.length}) #{src} => #{dest}"
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

  end

end
