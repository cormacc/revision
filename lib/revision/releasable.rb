require 'pathname'

class Revision::Releasable

  BUILD_DIR_BASE_NAME = "dist"
  BUILD_CONFIGURATION_DEFAULT = "default"
  BUILD_TARGET_DEFAULT = "production"
  # RELATIVE_PATH_TO_BOOTLOADER = File.join("..","bootloader")
  RELATIVE_PATH_TO_BOOTLOADER = "bootloader"

  attr_reader :name
  attr_reader :path
  attr_reader :configuration
  attr_reader :target

  def initialize(name: nil, configuration: BUILD_CONFIGURATION_DEFAULT, unified_image: false)
    # ver = options[:version] || 0.0
    @target = BUILD_TARGET_DEFAULT
    @configuration=configuration
    @unified_image = unified_image

    if(name)
      @path = File.join(Dir.getwd, name);
    else
      @path = Dir.getwd
    end
    @name = File.basename(@path)
  end

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
