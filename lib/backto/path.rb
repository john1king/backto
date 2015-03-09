require "fileutils"

module Backto

  class Path

    def initialize(config, path)
      @config = config
      @path = path
    end

    def target
      @target ||= File.join(@config[:to], @path)
    end

    def source
      @source ||= File.join(@config[:from], @path)
    end

    def mkdirs
      FileUtils.mkdir_p target, verbose: @config[:verbose] unless File.exist? target
    end

    def hardlink
      FileUtils.ln source, target, link_options
    rescue Errno::EEXIST
      raise unless hardlinked?
    end

    def softlink
      return if softlinked?
      if File.directory?(target) && File.directory?(source)
        FileUtils.rm_r target, link_options if link_options[:force]
        FileUtils.ln_s source, File.dirname(target), link_options
      else
        FileUtils.ln_s source, target, link_options
      end
    end

    def softlinked?
      File.symlink?(target) && File.readlink(target) == source
    end

    def hardlinked?
      File.stat(target).ino == File.stat(source).ino
    rescue Errno::ENOENT
      false
    end

    def link_options
      @link_options ||= {verbose: @config[:verbose], force: @config[:force]}
    end

  end

end
