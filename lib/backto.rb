require "backto/version"
require "backto/config"
require "fileutils"

module Backto

  class Execute

    def initialize(config)
      config = Config.new(config) unless config.is_a? Config
      @config = config
      @back_files = {}
    end

    def run
      scan_directory(from_path) do |path, is_dir|
        if is_dir && !link_directory?(path)
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
      begin
        FileUtils.ln_s source, target, opts
      rescue Errno::EEXIST
        raise unless softlink? target, source
      end
      notify(source, target, 'softlink')
    end

    def exclude?(path, is_dir)
      full_path = File.join('/', path)
      exclude_patterns.any? do |pattern, match_dir|
        matched = File.fnmatch? pattern, full_path, File::FNM_PATHNAME | File::FNM_DOTMATCH
        matched && (match_dir ? is_dir : true)
      end
    end

    def exclude_patterns
      @exclude_patterns ||= @config[:exclude_patterns].map do |pattern|
        normalized = pattern.dup
        match_dir = normalized.chomp!('/') != nil
        normalized = '/**/' + normalized unless normalized.start_with?('/')
        [normalized, match_dir]
      end
    end

    def link_directory?(path)
      if @config[:link_directory].is_a? Array
        @config[:link_directory].include? path
      else
        @config[:link_directory]
      end
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

    # only return the relate part of source path
    def scan_directory(parent, path = nil, &blk)
      Dir.foreach(parent) do |name|
        next if name == '.' || name == '..'
        rel_path = path ? File.join(path, name) : name
        full_path = File.join(parent, name)
        is_dir = File.directory? full_path
        next if exclude? rel_path, is_dir
        blk.call(rel_path, is_dir)
        scan_directory(full_path, rel_path, &blk) if is_dir && recursive?(rel_path)
      end
    end

    # don't recursive directry when link_directory is true
    def recursive?(path)
      if @config[:link_directory] == true
        false
      else
        !link_directory?(path)
      end
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
