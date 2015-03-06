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
      scan(@entry, nil, &block)
    end

    private

    # only return the relate part of source path
    def scan(parent, path = nil, &block)
      Dir.foreach(parent) do |name|
        next if name == '.' || name == '..'
        rel_path = path ? File.join(path, name) : name
        full_path = File.join(parent, name)
        is_dir = File.directory? full_path
        next if exclude? rel_path, is_dir
        is_recursive = is_dir && recursive?(rel_path)
        block.call(rel_path, is_dir, is_recursive)
        scan(full_path, rel_path, &block) if is_recursive
      end
    end

    def exclude?(path, is_dir)
      full_path = File.join('/', path)
      exclude_patterns.any? do |pattern, match_dir|
        fnmatch?(pattern, full_path) && (match_dir ? is_dir : true)
      end
    end

    def recursive?(path)
      if @skip_recursive.is_a? Array
        !@skip_recursive.include? path
      else
        !@skip_recursive
      end
    end

    def fnmatch?(pattern, path)
       File.fnmatch? pattern, path, File::FNM_PATHNAME | File::FNM_DOTMATCH
    end
  end

end
