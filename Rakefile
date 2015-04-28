#!/usr/bin/env rake
require 'rake/testtask'

Rake::TestTask.new :test do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.libs.push 'spec'
end

task :build => :test do
  system('gem build argparser.gemspec')
end

task :lint do
  system('rubocop -f s')
end

task :default => :test
