require "backto/version"
require "backto/config"
require "backto/scanner"
require "fileutils"

module Backto

  class Execute

    def initialize(config)
      config = Config.new(config) unless config.is_a? Config
      @config = config
      @back_files = {}
      @scanner = Scanner.new(from_path, @config[:exclude_patterns], @config[:link_directory])
    end

    def run
      @scanner.each do |path, is_dir, is_recursive|
        if is_dir && is_recursive
          mkdirs to_path(path), verbose: @config[:verbose]
        else
          args = [
            from_path(path),
            to_path(path),
            {
              verbose: @config[:verbose],
              force: @config[:force],
            }
          ]
          if @config[:hardlink] && !is_dir
            hardlink *args
          else
            softlink *args
          end
        end
      end
      clean_link
    end

    def hardlink(source, target, opts)
      begin
        FileUtils.ln source, target, opts
      rescue Errno::EEXIST
        raise unless hardlink? target, source
      end
      notify(source, target, 'hardlink')
    end

    def softlink(source, target, opts)
      unless softlink? target, source
        if File.directory?(target) && File.directory?(source)
          FileUtils.rm_r target, opts if opts[:force]
          FileUtils.ln_s source, File.dirname(target), opts
        else
          FileUtils.ln_s source, target, opts
        end
      end
      notify(source, target, 'softlink')
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
