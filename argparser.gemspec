# coding: utf-8
Gem::Specification.new do |spec|
  spec.name          = 'argparser'
  spec.version       = '1.0.0'
  spec.authors       = ['sinm']
  spec.email         = 'sinm.sinm@gmail.com'
  spec.summary       = 'Command line argument parser'
  spec.description   = '== Trying to follow POSIX and GNU guidelines'
  spec.homepage      = 'https://github.com/sinm/argparser'
  spec.license       = 'MIT'
  spec.files         = `git ls-files -z`.split("\x0")
  spec.require_paths = ['lib']

  #spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  #spec.test_files    = spec.files.grep(%r{^test/})
  #spec.add_development_dependency "bundler", "~> 1.7"
  #spec.add_development_dependency "rake", "~> 10.0"
  #spec.add_development_dependency "minitest" if RUBY_VERSION > '1.8'
end
