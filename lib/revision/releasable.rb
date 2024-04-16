require 'pathname'
require 'yaml'
require 'zip'
# require 'rugged'

module Revision

  class Releasable

    BUILD_DIR_BASE_NAME = "dist"
    BUILD_CONFIGURATION_DEFAULT = "default"
    BUILD_TARGET_DEFAULT = "production"
    # RELATIVE_PATH_TO_BOOTLOADER = File.join("..","bootloader")
    RELATIVE_PATH_TO_BOOTLOADER = "bootloader"

    CONFIG_FILE_NAME = 'releasables.yaml'.freeze

    REVISION_PLACEHOLDER = /<REV>|<VER>/

    attr_reader :root, :id, :revision, :build_steps, :artefacts, :git_tag_prefix, :secondary_revisions

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

    # def git_repo
    #   @git_repo ||= Rugged::Repository.discover('.')
    #   puts 'WARNING: No git repo found in this directory or its ancestors' if @git_repo.nil?
    #   @git_repo
    # end

    def _build_revision_info(definition, embed_changelog: true)
      Info.new(File.join(@root,definition[:src]), regex: definition[:regex], comment_prefix: definition[:comment_prefix], embed_changelog: embed_changelog)
    end

    def initialize(root: nil, config: {})

      root ||= Dir.getwd
      @root = Pathname.new(root).realpath
      @id = config[:id] || File.basename(@root)
      @revision = _build_revision_info(config[:revision], embed_changelog: true)
      @secondary_revisions = config[:secondary_revisions].nil? ? [] : config[:secondary_revisions].map { |r| _build_revision_info(r, embed_changelog:false)}
      @git_tag_prefix = config[:revision][:git_tag_prefix].nil? ? 'v' : "#{config[:revision][:git_tag_prefix]}_v"
      # Legacy definition syntax compatibility
      @build_def = config[:build] ? config[:build] : { environment: { variables: {}}, steps: config[:build_steps]}
      @artefacts = config[:artefacts] || []
      @artefacts.each { |a| a[:dest] ||= File.basename(a[:src]) } unless @artefacts.nil? || @artefacts.empty?
      # @artefacts.each { |a| a[:chk] = true if a[:chk].nil? } unless @artefacts.nil? || @artefacts.empty?
      @config = config
    end

    def to_s
      <<~EOT
      #{@id} v#{@revision} @ #{@root}

        Build environment:
        #{@build_def[:environment]}

        Build pipeline:
        - #{@build_def[:steps].nil? ? 'empty' : @build_def[:steps].join("\n  - ")}

        Build artefacts:
        #{@artefacts.empty? ? '- None defined' : @artefacts.map{ |a| "- #{a[:src]}\n    => #{a[:dest]}" }.join("\n") }

        Git commit details:
        - log entry: #{commit_message}
        Git tag id #{tag_id} / annotation:
          #{tag_annotation.gsub("\n","\n    ")}

      EOT
    end

    def exec_pipeline(type, steps, skip_steps=0)
      exec_steps = steps[skip_steps..-1]
      puts "#{type} :: Executing steps #{skip_steps+1} to #{steps.length}..."
      Dir.chdir(@root) do
        exec_steps.each_with_index do |step, index|
          step_index = index+1+skip_steps
          puts "... (#{step_index}/#{steps.length}) #{step}"
          system(step)
          puts "{type} :: WARNING: step #{step_index}: #{step} exit status #{$?.exitstatus}" unless $?.exitstatus.zero?
        end
      end

    end

    def build(skip_steps = 0)
      if @build_def.dig(:environment, :variables)
        @build_def[:environment][:variables].each do |key, value|
          if(key.match?('PATH'))
            if Gem.win_platform?
              value.gsub!(':', ';')
              value.gsub!('/', '\\')
            else
              value.gsub!(';', ':')
              value.gsub!('\\', '/')
            end
            value.gsub!('~', Dir.home)
          end
          puts "Setting environment variable '#{key}' to '#{value}'"
          ENV[key] = value
        end
      end
      exec_pipeline('build', @build_def[:steps], skip_steps)
      # steps = @build_def[:steps][skip_steps..-1]
      # puts "Executing #{steps.length} of #{@build_def[:steps].length} build steps..."
      # Dir.chdir(@root) do
      #   steps.each_with_index do |step, index|
      #     step_index = index+1+skip_steps
      #     puts "... (#{step_index}/#{@build_def[:steps].length}) #{step}"
      #     system(step)
      #     puts "WARNING: build step #{step_index}: #{step} exit status #{$?.exitstatus}" unless $?.exitstatus.zero?
      #   end
      # end
    end

    def tag_id
      "#{@git_tag_prefix}#{revision}"
    end

    def escape(a_string)
      a_string.gsub('"',"\\\"")
    end

    def tag_annotation
      escape(@revision.last_changelog_entry.join("\n"))
    end

    def commit_message
      changelog_entry = @revision.last_changelog_entry
      #Insert a blank line between the revision header and release notes, as per git commit best practice
      commit_lines = ["#{tag_id} #{changelog_entry[1]}", '']
      if changelog_entry.length > 2
        commit_lines << "Also..."
        commit_lines += changelog_entry[2..-1]
      end
      escape(commit_lines.join("\n"))
    end

    def tag
      Dir.chdir(@root) do
        puts "Committing..."
        puts commit_message
        system("git commit -a -m \"#{commit_message}\"")
        puts "Tagging as #{tag_id}"
        system("git tag -a #{tag_id} -m \"#{tag_annotation}\"")
      end
    end

    def push
      pushed = false
      Dir.chdir(@root) do
        pushed = system("git push") && system("git push --tags")
        puts "ERROR :: Failed to push to remote" unless pushed
      end
      pushed
    end

    def archive_name
      "#{@id}_v#{@revision}.zip"
    end

    def changelog_name
      "#{@id}_revision_history_v#{@revision}.txt"
    end

    def interp_rev(string)
      string.gsub(REVISION_PLACEHOLDER, @revision.to_s)
    end

    def normalise_artefact(a)
      src_norm = interp_rev(a[:src])
      # the :chk key replaced a legacy :md5 key -- support old syntax
      chk_unified = a[:chk].nil? ? a[:md5] : a[:chk]
      a_norm = {
        src: src_norm,
        dest: a[:dest].nil? ? File.basename(src_norm) : interp_rev(a[:dest]),
        chk: chk_unified.nil? ? true : chk_unified
      }
      if Gem.win_platform? && !a_norm[:src].end_with?('.exe') && File.exist?(File.join(@root, a_norm[:src] + '.exe'))
        puts "... windows platform -- appending '.exe' ('#{a_norm[:src]}' -> '#{a_norm[:src]}.exe')"
        a_norm[:src] += '.exe'
        a_norm[:dest] += '.exe' unless a_norm[:dest].end_with?('.exe')
      end
      a_norm
    end

    def artefacts
      @artefacts.map { |a| normalise_artefact(a)}
    end

    def archive
      puts "Archiving #{@artefacts.length} build artefacts as #{archive_name}..."
      if File.exist?(archive_name)
        puts "... deleting existing archive"
        File.delete(archive_name)
      end
      Zip::File.open(archive_name, Zip::File::CREATE) do |zipfile|
        zip_entries = artefacts
        zip_entries.each.with_index(1) do |a, idx|
          puts "... (#{idx}/#{zip_entries.length}) #{a[:dest]} :: <= #{a[:src]}"
          zipfile.add(a[:dest], a[:src])
          if a[:chk]
            chkfile = Checksum.from_file(a[:src])
            puts "... (#{idx}/#{zip_entries.length}) #{a[:dest]} :: embedding checksum (#{chkfile.chkfilename})"
            zipfile.get_output_stream(chkfile.chkfilename) { |os| os.write("#{chkfile}")}
          else
            puts "... (#{idx}/#{zip_entries.length}) #{a[:dest]} :: no checksum required"
          end
        end
        puts "... embedding revision history as #{changelog_name} "
        zipfile.get_output_stream(changelog_name) { |os| output_changelog(os)}
      end
      archive_checksum = Checksum.from_file(archive_name)
      puts "... generating archive checksum as #{archive_checksum.chkfilename} "
      archive_checksum.write

      if @config.dig(:archive)
        archive_root = File.expand_path(@config[:archive])
        puts "... moving #{archive_name} to #{archive_root}"
        FileUtils.mkdir_p(archive_root)
        FileUtils.mv(archive_name, archive_root)
        FileUtils.mv(archive_checksum.chkfilename, archive_root)
      end
    end

    def deploy_to(d)
      destination = File.expand_path(d[:dest])

      if d.dig(:pre)
        exec_pipeline('deploy (pre / #{d[:dest]})', d[:pre])
      end

      puts "Deploying #{artefacts.length} build artefacts to #{destination}..."
      if not File.exist?(destination)
        puts "... folder not found -> creating ... '#{destination}'"
        FileUtils.mkdir_p(destination)
      end
      artefacts.each.with_index(1) do |a, idx|
        # src, dest = entry
        src = File.join(@root,a[:src])
        dest = destination.empty? ? a[:dest] : File.join(destination, a[:dest])
        puts "... (#{idx}/#{artefacts.length}) #{src} => #{dest}"
        if File.exist?(dest)
          puts "... deleting existing '#{dest}' ..."
          FileUtils.rm_rf(dest)
        end
        puts "... deploying '#{src}' -> '#{dest}'"
        FileUtils.cp_r(src,dest)
        puts "... writing checksum for '#{dest}' to '#{Checksum.from_file(dest).write}'" if a[:chk]
      end
      File.open(File.join(destination,changelog_name),'w') { |f| output_changelog(f)}

      if d.dig(:post)
        exec_pipeline('deploy (post / #{d[:dest]})', d[:post])
      end
    end

    def deploy(destination='')
      destinations = []
      if not destination.empty?
        destinations.append({dest: destination})
      elsif @config.dig(:deploy)
        if @config[:deploy].kind_of?(Array)
          destinations.append(*@config[:deploy])
        else
          destinations.append(@config[:deploy])
        end
      end

      raise Errors::NotSpecified.new(':deploy') if destinations.empty?

      destinations.each do |d|
        if d.dig(:dest)
          deploy_to(d)
        elsif d.dig(:steps)
          exec_pipeline("deploy", d[:steps])
        else
          puts "ERROR: Please specify a series of deployment :steps: or a :dest: in releasables.yaml"
        end
      end

    end

    def package
      build
      archive
    end

    def output_changelog(output_stream)
      output_stream.puts "Revision history for #{@id} version #{@revision}"
      output_stream.puts ""
      @revision.changelog {|line| output_stream.puts(line)}
    end

  end

end
