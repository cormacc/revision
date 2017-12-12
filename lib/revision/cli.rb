require 'thor'

require_relative 'releasable'
require_relative 'info'
require_relative 'errors'

module Revision
  class CLI < Thor
    class_option :dryrun, :type => :boolean, :default =>false

    def initialize(*args)
      super
      #TODO Update this to traverse up the folder heirarchy until we find a releasables.yaml
      wd = Dir.getwd
      loop do
        begin
          @releasables = Releasable.from_folder(wd)
          break
        rescue Errors::NoDefinition
          break if wd == File.expand_path('..',wd)
          puts "No releasable found in #{wd}, trying parent..."
          wd = File.expand_path('..',wd)
          next
        end
      end
      raise 'No definition file found in this directory or its ancestors' if @releasables.nil? || @releasables.empty?
    end

    desc "info", 'Display info for all defined releasables'
    def info
      puts "Found #{@releasables.values.length} releasables"
      puts ''
      puts @releasables.values.map {|r| r.to_s}.join("\n\n")
    end

    desc "patch <MODULE_NAME>", "Increment patch revision index"
    def patch(releasable_id = nil)
      do_increment(releasable_id, 'patch')
    end

    desc "minor <MODULE_NAME>", "Increment minor revision index"
    def minor(releasable_id = nil)
      do_increment(releasable_id, 'minor')
    end

    desc "major <MODULE_NAME>", "Increment major revision index"
    def major(releasable_id = nil)
      do_increment(releasable_id, 'major')
    end

    desc "archive <MODULE_NAME>", "Archive module (default CWD)"
    def archive(releasable_id = nil)
      selected = releasable_id.nil? ? @releasables.values : [@releasables[releasable_id]]
      puts "Archiving #{selected.length} releasables..."
      selected.each do |r|
        r.build
        r.archive
      end
    end

    desc "changelog", "Display module change log on stdout"
    def changelog(releasable_id = nil)
      select_one(releasable_id).output_changelog($stdout)
    end

    private

    def select_one(releasable_id)
      raise "Please specify one of #{@releasables.keys}" if releasable_id.nil? && @releasables.keys.length > 1
      releasable_id ||= @releasables.keys[0]
      @releasables[releasable_id]
    end

    def do_increment(releasable_id, type)
      #TODO Add git commit and tag?
      r = select_one(releasable_id)
      increment_method = "#{type}_increment!"
      puts "Incrementing #{r.revision} to #{r.revision.public_send(increment_method)}"
      options[:dryrun] ? r.revision.write_to_file : r.revision.write!
    end

  end

end
