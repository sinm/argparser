begin
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
rescue LoadError
  $stderr.puts "CodeClimate is not started: #{$!.message}"
end

require 'minitest/autorun'
require 'argparser'

class ExitStub < RuntimeError
  attr_accessor :status
  def initialize(status, message)
    @status = status
    super(message)
  end
end

class ArgParser
  def on_exit(status, message)
    raise ExitStub.new(status, message)
  end
end
