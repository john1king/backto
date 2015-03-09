require "fileutils"

module Backto

  class Path
    attr_reader :relative

    def initialize(path_name, relative = nil)
      @path_name = path_name
      @relative = relative
    end

    def absolute
      @absolute ||= File.join(@path_name, relative || '')
    end

    alias :source :absolute

    def join(file)
      self.class.new(@path_name, relative ? File.join(relative, file) : file)
    end

    def chdir(path_name)
      File.join(path_name, relative)
    end

    def mkdirs(target, options = {})
      FileUtils.mkdir_p target, options unless File.exist? target
    end

    def hardlink(target, options)
      FileUtils.ln source, target, options
    rescue Errno::EEXIST
      raise unless hardlink? target
    end

    def softlink(target, options = {})
      return if softlink? target
      if File.directory?(target) && directory?
        FileUtils.rm_r target, options if options[:force]
        FileUtils.ln_s source, File.dirname(target), options
      else
        FileUtils.ln_s source, target, options
      end
    end

    def softlink?(target)
      File.symlink?(target) && File.readlink(target) == source
    end

    def hardlink?(target)
      File.stat(target).ino == File.stat(source).ino
    rescue Errno::ENOENT
      false
    end

    def directory?
      @is_directory ||= File.directory?(absolute)
    end

  end

end
