# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'delayer/deferred/version'

Gem::Specification.new do |spec|
  spec.name          = "delayer-deferred"
  spec.version       = Delayer::Deferred::VERSION
  spec.authors       = ["Toshiaki Asai"]
  spec.email         = ["toshi.alternative@gmail.com"]
  spec.summary       = %q{Deferred for Delayer}
  spec.description   = %q{Deferred for Delayer.}
  spec.homepage      = "https://github.com/toshia/delayer-deferred"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.4.0'

  spec.add_dependency "delayer", ">= 1.0", "< 2.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", ">= 12.3.2"
  spec.add_development_dependency "minitest", ">= 5.11.3"
  spec.add_development_dependency "simplecov", '>= 0.16.1'
  spec.add_development_dependency "ruby-prof", '>= 0.18.0'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-shell'
  spec.add_development_dependency 'guard-rake'
end
