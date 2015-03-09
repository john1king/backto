require "backto/version"
require "backto/config"
require "backto/scanner"
require "backto/path"

module Backto

  module_function

  def run(config)
    config = Config.create(config)
    link_options = {verbose: config[:verbose], force: config[:force]}
    scanner = Scanner.new(config[:from], config[:exclude_patterns], config[:link_directory])
    scanner.each do |path, is_recursive|
      target = path.chdir(config[:to])
      if path.directory? && is_recursive
        path.mkdirs target, verbose: config[:verbose]
      elsif config[:hardlink] && ! path.directory?
        path.hardlink target, link_options
      else
        path.softlink target, link_options
      end
    end
  end

end
