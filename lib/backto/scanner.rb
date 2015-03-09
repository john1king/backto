require "backto/path"

module Backto

  class Scanner
    attr_reader :exclude_patterns

    def self.normalize_patterns(patterns)
      patterns.map do |pattern|
        normalized = pattern.dup
        match_dir = normalized.chomp!('/') != nil
        normalized = '/**/' + normalized unless normalized.start_with?('/')
        [normalized, match_dir]
      end
    end

    def initialize(entry, exclude_patterns = [], skip_recursive = false)
      @entry = entry
      @skip_recursive = skip_recursive
      @exclude_patterns = self.class.normalize_patterns(exclude_patterns)
    end

    def each(&block)
      scan Path.new(@entry), &block
    end

    private

    def scan(parent, &block)
      Dir.foreach(parent.absolute) do |name|
        next if name == '.' || name == '..'
        path = parent.join(name)
        next if exclude? path
        is_recursive = recursive?(path)
        block.call(path, is_recursive)
        scan(path, &block) if is_recursive
      end
    end

    def exclude?(path)
      test_path = File.join('/', path.relative)
      exclude_patterns.any? do |pattern, match_dir|
        fnmatch?(pattern, test_path) && (match_dir ? path.directory? : true)
      end
    end

    def recursive?(path)
      return false unless path.directory?
      if @skip_recursive.is_a? Array
        !@skip_recursive.include? path.relative
      else
        !@skip_recursive
      end
    end

    def fnmatch?(pattern, path_name)
       File.fnmatch? pattern, path_name, File::FNM_PATHNAME | File::FNM_DOTMATCH
    end
  end

end
