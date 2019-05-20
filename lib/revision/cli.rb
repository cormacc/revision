require 'thor'

require_relative 'releasable'
require_relative 'info'
require_relative 'errors'
require_relative 'version'

module Revision
  class CLI < Thor
    class_option :dryrun, :type => :boolean, :default =>false
    class_option :id, :default => nil #Initialized after loading definition
    map %w[--version -v] => :__print_version

    def initialize(*args)
      super
      wd = Dir.getwd
      loop do
        begin
          @releasables = Releasable.from_folder(wd)
          break
        rescue Errors::NoDefinition
          break if wd == File.expand_path('..', wd)
          puts "No releasable found in #{wd}, trying parent..."
          wd = File.expand_path('..', wd)
          next
        end
      end
      raise 'No definition file found in this directory or its ancestors' if @releasables.nil? || @releasables.empty?
      @id = options[:id] || @releasables.keys[0]
    end

    desc "--version, -v", "print the version"
    def __print_version
      puts Revision::VERSION
    end

    desc 'info', 'Display info for all defined releasables'
    def info
      puts "Found #{@releasables.values.length} releasables"
      puts ''
      puts @releasables.values.map(&:to_s).join("\n\n")
      puts ''
      puts "Default releasable ID: #{@id}"
    end

    desc 'patch', 'Increment patch revision index'
    def patch
      do_increment('patch')
    end

    desc 'minor', 'Increment minor revision index'
    def minor
      do_increment('minor')
    end

    desc 'major', 'Increment major revision index'
    def major
      do_increment('major')
    end

    desc 'build', 'Build releasable(s)'
    method_option :skip, :aliases => "-s", :type => :numeric, :default => 0, :desc => "Skip the specified number of build steps"
    def build
      selected = options[:id].nil? ? @releasables.values : [@releasables[options[:id]]]
      puts "Building #{selected.length} releasable(s)..."
      # selected.each(&:build)
      selected.each { |r| r.build(options[:skip])}
    end

    desc 'archive', 'Archive releasable(s)'
    def archive
      selected = options[:id].nil? ? @releasables.values : [@releasables[options[:id]]]
      puts "Archiving #{selected.length} releasables..."
      selected.each do |r|
        r.archive
      end
    end

    desc 'deploy', 'Deploy releasable(s)'
    method_option :to, :aliases => "-t", :type => :string, :default => '', :desc => "Path to deploy to"
    def deploy
      selected = options[:id].nil? ? @releasables.values : [@releasables[options[:id]]]
      puts "Deploying #{selected.length} releasables..."
      selected.each do |r|
        r.deploy(options[:to])
      end
    end

    desc 'package', 'Build and archive releasables'
    def package
      selected = options[:id].nil? ? @releasables.values : [@releasables[options[:id]]]
      puts "Building and archiving #{selected.length} releasables..."
      selected.each do |r|
        r.package
      end
    end

    desc 'changelog', 'Display change log on stdout'
    def changelog
      select_one.output_changelog($stdout)
    end

    desc 'tag', 'Commit the current revision to a local git repo and add a version tag'
    def tag
      select_one.tag
    end

    private

    def id_options
      @releasables.keys.map { |id| "'-id #{id}'"}.join(', ')
    end

    def select_one
      raise "Please specify one of #{id_options}" if options[:id].nil? && @releasables.keys.length > 1
      @releasables[@id]
    end

    def do_increment(type)
      r = select_one
      increment_method = "#{type}_increment!"
      say "Incrementing #{r.revision} to #{r.revision.public_send(increment_method)}"
      options[:dryrun] ? r.revision.write_to_file : r.revision.write!
      say ''
      say "The automatic commit / tag step assumes you're only checking in changes to existing files"
      say "You can answer 'n' at the prompt and use 'revision tag' to generate a commit with the latest changelog entry and an associated tag after manually adding any new files to the repo"
      say ""
      if ask("Rebuild and archive any releasables (Y/n)?").upcase!='N'
        r.package
      end
      if ask("Commit changes to existing files and add a Git tag (Y/n)?").upcase!='N'
        r.tag
        if ask("Push changes/tag to origin (Y/n)?").upcase=='N' || !r.push
          say "To push from the command line, type 'git push --tags' at a shell prompt"
        end
      end
    end

  end

end
