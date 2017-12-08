require 'thor'
require 'rubygems'
require 'zip'
require 'pathname'

require_relative 'releasable'
require_relative 'info'
module Revision
  class CLI < Thor
    class_option :dryrun, :type => :boolean, :default =>false

    ROOT = Pathname.new(__FILE__).expand_path.dirname
    BUILD_DIR_BASE_NAME = "dist"
    BUILD_TARGET_DEFAULT = "production"

    desc "info <MODULE_NAME>", "Read current module revision info"
    def info(module_name = nil)
      # module_info, revision_info = load(module_name)
      load(module_name)
    end

    desc "patch <MODULE_NAME>", "Increment patch revision index"
    def patch(module_name = nil)
      _, revision_info = load(module_name)
      puts "Incrementing #{revision_info} to #{revision_info.patch_increment!}"
      options[:dryrun] ? revision_info.write_to_file : revision_info.write!
    end

    desc "minor <MODULE_NAME>", "Increment minor revision index"
    def minor(module_name = nil)
      _, revision_info = load(module_name)
      puts "Incrementing #{revision_info} to #{revision_info.minor_increment!}"
      options[:dryrun] ? revision_info.write_to_file : revision_info.write!
    end

    desc "major <MODULE_NAME>", "Increment major revision index"
    def major(module_name = nil)
      _, revision_info = load(module_name)
      puts "Incrementing #{revision_info} to #{revision_info.major_increment!}"
      options[:dryrun] ? revision_info.write_to_file : revision_info.write!
    end

    desc "archive <MODULE_NAME>", "Archive module (default CWD)"
    def archive(module_name = nil)

      module_info, ver = load(module_name)

      zipfile_name = "#{module_info.name}_v#{ver}.zip"
      if File.exist?(zipfile_name)
        puts "Deleting existing archive: #{zipfile_name}"
        File.delete(zipfile_name)
      end

      puts "Archiving module #{module_info.name} version #{ver}"
      Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
        Dir.chdir(module_info.path) { %x['make'] }
        puts "... adding #{module_info.get_image_path}"
        zipfile.add("#{module_info.name}_v#{ver}.hex", module_info.get_image_path)
        # if module_info.is_bootloadable
        #   puts("Archiving bootloader")
        #   #FIXME: Update this to work with new directory structure
        #   bootloader_revision_info = Info.new(module_info.get_bootloader_info)
        #   Dir.chdir(module_info.get_bootloader_info.path) {
        #     system("make")
        #     #To build a particular config: "make -f Makefile CONF=Configuration"
        #   }
        #   zipfile.add("#{module_info.name}_v#{ver}_with_bootloader_v#{bootloader_revision_info}.hex", module_info.get_bootloader_info.get_image_path)
        #   puts "... adding #{module_info.get_bootloader_info.get_image_path}"
        #   zipfile.add("#{module_info.name}_v#{ver}_with_bootloader.hex", module_info.get_bootloader_info.get_image_path)
        #   #zipfile.get_output_stream("FrameworkRevisionHistory.txt") { |os| output_changelog(bootloader_revision_info, os)}
        # end
        zipfile.get_output_stream("RevisionHistory.txt") { |os| output_changelog(ver, os)}
      end
    end

    desc "changelog", "Display module change log on stdout"
    def changelog(module_name = nil)
      _, revision_info = load(module_name)
      output_changelog(revision_info, $stdout)
    end

    private

    def output_changelog(revision_info, output_stream)
      output_stream.puts "Revision history for #{revision_info.module_info.name.upcase} version #{revision_info}"
      output_stream.puts ""
      revision_info.changelog {|line| output_stream.puts(line)}
    end

    def load(module_name)
      module_info = Releasable.new(name: module_name)
      begin
        revision_info = Info.new(module_info);
      rescue StandardError
        module_info = Releasable.new(name:"firmware", configuration: "bootloadable")
        revision_info = Info.new(module_info);
      end
      puts "Found #{module_info.name} v#{revision_info} :: build path #{module_info.get_build_path}"
      return module_info, revision_info
    end
  end

end
