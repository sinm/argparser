# coding: utf-8
Gem::Specification.new do |spec|
  spec.name          = 'argparser'
  spec.version       = '1.0.1'
  spec.authors       = ['sinm']
  spec.email         = 'sinm.sinm@gmail.com'
  spec.summary       = 'Command line argument parser library trying to follow POSIX and GNU guidelines'
  spec.description   = '== Command line argument parser library trying to follow POSIX and GNU guidelines'
  spec.homepage      = 'https://github.com/sinm/argparser'
  spec.license       = 'MIT'
  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = `git ls-files -z spec/`.split("\0")
  spec.require_paths = ['lib']
  #spec.extra_rdoc_files = 'README.md'
  #spec.rdoc_options  << '--title' << 'argparser' <<
  #                      '--main' << 'README'     <<
  #                      '--markup' << 'markdown' <<
  #                      '--line-numbers'
  spec.add_development_dependency 'rake',       '~> 10'
  spec.add_development_dependency 'minitest',   '~> 4'
end
