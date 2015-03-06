require "json"
require "pathname"

module Backto

  class Config

    EXCLUDE_PATTERNS = [
      '.git',
      '.svn',
      '.DS_Store',
      '*.swp',
    ].freeze

    DEFAULT = {
      verbose: true,
      force: false,
      hardlink: false,
      link_direcotry: false,
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

    def from
      str @base_path + fetch(:from)
    end

    def to
      str @base_path + fetch(:to)
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
