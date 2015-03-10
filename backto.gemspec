# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'backto/version'

Gem::Specification.new do |spec|
  spec.name          = "backto"
  spec.version       = Backto::VERSION
  spec.authors       = ["john1king"]
  spec.email         = ["uifantasy@gmail.com"]
  spec.summary       = %q{Link files easier}
  spec.description   = %q{A simple command line tool for backup files to one location}
  spec.homepage      = "https://github.com/john1king/backto"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
