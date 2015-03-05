require "backlist/version"
require "backlist/config"
require "fileutils"

module Backlist

  class Execute

    def initialize(config)
      config = Config.new(config) unless config.is_a? Config
      @config = config
    end

    def run(opts = {})
      scan_directory(source_path) do |path, is_dir|
        if is_dir && !link_directory?(path)
          mkdirs target_path(path), verbose: @config[:verbose]
        else
          ln_s source_path(path), target_path(path), {
            force: @config[:force],
            verbose: @config[:verbose]
          }
        end
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

    def ln_s(source, target, opts = {})
      FileUtils.ln_s source, target, opts
    end

    def source_path(path='.')
      File.expand_path File.join(@config[:source_path], path)
    end

    def target_path(path='.')
      File.expand_path File.join(@config[:target_path], path)
    end

    # only return the relate part of srouce path
    def scan_directory(parent, path = nil, &blk)
      Dir.foreach(parent) do |name|
        next if name == '.' || name == '..'
        rel_path = path ? File.join(path, name) : name
        full_path = File.join(parent, name)
        if File.directory? full_path
          blk.call(rel_path, true)
          scan_directory(full_path, rel_path, &blk) if recursive? rel_path
        else
          blk.call(rel_path, false)
        end
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

  end

end
