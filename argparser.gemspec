# coding: utf-8
require File.expand_path('../lib/argparser/version.rb', __FILE__)

Gem::Specification.new do |s|
  s.name          = 'argparser'
  s.version       = ArgParser::VERSION
  s.authors       = ['sinm']
  s.email         = 'sinm.sinm@gmail.com'
  s.summary       = 'Yet another ruby command line argument parser library'
  s.description   = '== Yet another ruby command line argument parser library'
  s.homepage      = 'https://github.com/sinm/argparser'
  s.license       = 'MIT'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/`.split("\n")
  s.require_paths = ['lib']
  s.bindir        = 'bin'
  s.executables   = `git ls-files -- bin/`.split("\n").map{|f| File.basename(f)}
  s.add_development_dependency 'bundler',    '~> 1.7'
  s.add_development_dependency 'rake',       '~> 10.1'
  s.add_development_dependency 'minitest',   '~> 4.7'
  s.add_development_dependency 'rubocop',    '~> 0.30'
end
