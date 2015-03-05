require "json"
require "pathname"

module Backlist

  class Config

    EXCLUDE_PATTERNS = [
      '.git',
      '.svn',
      '.DS_Store',
      '*.swp',
    ].freeze

    DEFAULT = {
      link_direcotry: false,
      verbose: true,
      force: false,
      exclude_patterns: EXCLUDE_PATTERNS,
    }.freeze

    def initialize(config = {})
      if config.is_a? String
        @config = JSON.parse(File.read(config), symbolize_names: true)
        @base_path = Pathname.new(config).dirname.expand_path
      else
        @config = config
        @base_path = Pathname.pwd
      end
    end

    def source_path
      str @base_path + fetch(:source_path)
    end

    def target_path
      str @base_path + fetch(:target_path)
    end

    def [](name)
      method = name.to_sym
      if respond_to? method
        send method
      elsif @config.key? method
        @config[method]
      else
        DEFAULT[method]
      end
    end

    private

    def fetch(name)
      @config.fetch(name)
    end

    def str(obj)
      obj.to_s
    end

  end

end
