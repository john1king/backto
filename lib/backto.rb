require "backto/version"
require "backto/config"
require "backto/scanner"
require "backto/path"

module Backto

  module_function

  def run(config)
    config = Config.create(config)
    scanner = Scanner.new(config[:from], config[:exclude_patterns], config[:link_directory])
    scanner.each do |path, is_dir, is_recursive|
      path = Path.new(config, path)
      if is_dir && is_recursive
        path.mkdirs
      else
        config[:hardlink] && !is_dir ? path.hardlink : path.softlink
      end
    end
  end

end
