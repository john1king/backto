require "json"

module Backto

  class Config

    LAST_BACKTO_FILE = '.last_backto'

    EXCLUDE_PATTERNS = [
      '.git',
      '.svn',
      '.DS_Store',
      '*.swp',
      LAST_BACKTO_FILE,
    ].freeze

    DEFAULT = {
      verbose: true,
      force: false,
      hardlink: false,
      link_directory: false,
      exclude_patterns: EXCLUDE_PATTERNS,
      clean_link: false,
    }.freeze

    def self.create(config)
      config.is_a?(self) ? config : new(config)
    end

    def initialize(config = {})
      if config.is_a? String
        @config = JSON.parse(File.read(config), symbolize_names: true)
        @base_path = File.expand_path(File.dirname(config))
      else
        @config = config
        @base_path = Dir.pwd
      end
    end

    def from
      @from ||= expand_path fetch(:from)
    end

    def to
      @to ||= expand_path fetch(:to)
    end

    def last_backto_file
      expand_path(@config[:last_backto_file]) || File.join(to, LAST_BACKTO_FILE)
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

    def expand_path(path)
      File.expand_path path, @base_path
    end

    def fetch(name)
      @config.fetch(name)
    end
  end

end
