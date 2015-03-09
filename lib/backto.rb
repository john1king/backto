require "backto/version"
require "backto/config"
require "backto/scanner"
require "fileutils"

module Backto

  class Path

    def initialize(config, path)
      @config = config
      @path = path
    end

    def target
      @target ||= File.expand_path File.join(@config[:to], @path)
    end

    def source
      @source ||= File.expand_path File.join(@config[:from], @path)
    end

    def link_options
      @link_options ||= {verbose: @config[:verbose], force: @config[:force]}
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

  end

  class Execute
    attr_reader :config

    def initialize(config)
      config = Config.new(config) unless config.is_a? Config
      @config = config
      @scanner = Scanner.new(from_path, @config[:exclude_patterns], @config[:link_directory])
    end

    def run
      @scanner.each do |path, is_dir, is_recursive|
        path = Path.new(@config, path)
        if is_dir && is_recursive
          mkdirs path.target, verbose: @config[:verbose]
        else
          @config[:hardlink] && !is_dir ? path.hardlink : path.softlink
        end
      end
    end

    def mkdirs(path, opts = {})
      FileUtils.mkdir_p path, opts unless File.exist? path
    end

    def from_path(path='.')
      File.expand_path File.join(@config[:from], path)
    end

  end

end
