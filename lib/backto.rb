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
      File.expand_path File.join(@config[:to], @path)
    end

    def source
      File.expand_path File.join(@config[:from], @path)
    end

  end

  class Execute

    def initialize(config)
      config = Config.new(config) unless config.is_a? Config
      @config = config
      @back_files = {}
      @scanner = Scanner.new(from_path, @config[:exclude_patterns], @config[:link_directory])
    end

    def run
      link_opts = {verbose: @config[:verbose], force: @config[:force]}
      @scanner.each do |path, is_dir, is_recursive|
        path = Path.new(@config, path)
        if is_dir && is_recursive
          mkdirs path.target, verbose: @config[:verbose]
        else
          @config[:hardlink] && !is_dir ? hardlink(path, link_opts) : softlink(path, link_opts)
        end
      end
      clean_link
    end

    def hardlink(path, opts)
      begin
        FileUtils.ln path.source, path.target, opts
      rescue Errno::EEXIST
        raise unless hardlink? path.target, path.source
      end
      notify(path.source, path.target, 'hardlink')
    end

    def softlink(path, opts)
      unless softlink? path.target, path.source
        if File.directory?(path.target) && File.directory?(path.source)
          FileUtils.rm_r path.target, opts if opts[:force]
          FileUtils.ln_s path.source, File.dirname(path.target), opts
        else
          FileUtils.ln_s path.source, path.target, opts
        end
      end
      notify(path.source, path.target, 'softlink')
    end

    def mkdirs(path, opts = {})
      FileUtils.mkdir_p path, opts unless File.exist? path
    end

    def from_path(path='.')
      File.expand_path File.join(@config[:from], path)
    end

    def to_path(path='.')
      File.expand_path File.join(@config[:to], path)
    end

    def notify(source, target, type)
      @back_files[target] = [source, type]
    end

    def clean_link
      return unless @config[:clean_link]
      file = @config[:last_backto_file]
      if File.exist?(file)
        last_files = JSON.parse(File.read(@config[:last_backto_file]))
        remove_old_link(last_files)
      else
        last_files = []
      end
      status = @back_files.map {|target, (source, type)| [target, source, type]}
      File.write(@config[:last_backto_file], status.to_json)
    end

    def remove_old_link(last_files)
      last_files.each do |target, source, type|
        # do nothing if target file is overwritted
        next if @back_files.key? target
        case type
        when 'softlink'
          if softlink? target, source
            FileUtils.rm_f target, verbose: @config[:verbose]
          end
        when 'hardlink'
          # WARN: if delete file from source, will delete target file too
          if !File.exist?(source) || hardlink?(target, source)
            FileUtils.rm_f target, verbose: @config[:verbose]
          end
        end
      end
    end

    def softlink?(sym_file, source)
      File.symlink?(sym_file) && File.readlink(sym_file) == source
    end

    def hardlink?(target, source)
      File.stat(target).ino == File.stat(source).ino
    rescue Errno::ENOENT
      false
    end

  end

end
