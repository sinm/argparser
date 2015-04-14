#!/usr/bin/env rake
require 'rake/testtask'

Rake::TestTask.new :test do |t|
  # t.test_files = FileList['spec/*_spec.rb']
  t.pattern = 'spec/**/*_spec.rb'
  t.libs.push 'spec'
end

task :build do
  system('gem build argparser.gemspec')
  # gem push argparser-1.0.0.gem
  # gem uninstall argparser
  # gem install argparser-1.0.0.gem
end

task :default   => :test
