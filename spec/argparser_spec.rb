# coding: utf-8
require 'spec_helper'

a_manifest = {
  :program  => 'a_example',  # Use additional properties like these:
  :version  => '1.0',        #   :info, :copyright, :license,
  :copyright=> '2015 sinm',
  :info => 'A Example',
  :license  => 'MIT',
  :package  => 'ArgParser Spec',
  :bugs     => 'https://github.com/sinm/argparser',
  :homepage => 'https://github.com/sinm/argparser',
  :options  => [{            #   :package, :bugs, :homepage
    :names      => %w[m mode],
    :param      => 'first|second|third',
    :default    => 'first',
    :multiple   => true,
    :help       => 'Example mode.',
    :validate   => (lambda {|this, _parser|  # Validating value in-line
      possible = this.param.split('|')
      this.value.select{|v| possible.include?(v)}.size == this.value.size })
  }],
  :arguments => [{
    :name       => 'file',
    :required   => false,
    :default    => '-',
    :help       => 'Filename or - for stdin.'
  }]
}

describe 'manifest' do
  it 'should compile option objects' do
    args = ArgParser.new(a_manifest)
    args.options.each {|o|
      o.must_be_instance_of(ArgParser::Option)
      args[o.name].must_be_same_as(o)
    }
    (a = args.parse!(%w[-])).must_be_instance_of(ArgParser)
    a.must_be_same_as(args)
  end

  it 'should require program' do
    b_manifest = a_manifest.merge(:program => '')
    lambda { ArgParser.new(b_manifest) }.must_raise(ArgParser::ManifestError)
  end

  it 'should require version' do
    b_manifest = a_manifest.merge(:version => nil)
    lambda { ArgParser.new(b_manifest) }.must_raise(ArgParser::ManifestError)
  end

  it 'requires nothing but but program & version' do
    b_manifest = a_manifest.reduce({}) {|h, (k, v)|
      h[k] = v if [:program, :version].include?(k); h}
    ArgParser.new(b_manifest).parse!([]).must_be_instance_of(ArgParser)
  end
end

describe 'Built-in options' do
  it 'prints out version and terminates' do
    a = ArgParser.new(a_manifest)
    e = lambda {
      a.parse!(%w[any --othelp --version])
    }.must_raise(ExitStub)
    e.status.must_equal(0)
    e.message.must_match(/#{a_manifest[:program]}.*#{a_manifest[:version]}/)
    e.message.must_equal(
      "a_example (ArgParser Spec) 1.0
Copyright (C) 2015 sinm
License: MIT\n")
  end

  it 'prints out help and terminates' do
    a = ArgParser.new(a_manifest)
    e = lambda {
      a.parse!(%w[any --oth --help])
    }.must_raise(ExitStub)
    e.status.must_equal(0)
    e.message.must_match(/#{a_manifest[:options].last[:help]}/)
    e.message.must_equal(
      "Usage: a_example [-m, --mode first|second|third]... [file]
A Example
OPTIONS:
[-m, --mode first|second|third]...
\tExample mode.
\tDefaults to: first
[--help]
\tPrint this help and exit.
[--version]
\tPrint version and exit.
ARGUMENTS:
[file]
\tFilename or - for stdin.
\tDefaults to: -
Report bugs to: https://github.com/sinm/argparser
ArgParser Spec home page: https://github.com/sinm/argparser\n")

  end

  it 'prints synopsys on argument error' do
    a = ArgParser.new(a_manifest)
    e = lambda {
      a.parse!(%w[any --1287])
    }.must_raise(ExitStub)
    e.status.must_equal(2)
    e.message.must_match(/#{a.synopsis}/)
  end

  it 'prints user-defined help if specified' do
    b_manifest = a_manifest.merge(:help => 'User-defined help')
    a = ArgParser.new(b_manifest)
    e = lambda {
      a.parse!(%w[--help])
    }.must_raise(ExitStub)
    e.status.must_equal(0)
    e.message.must_match(/#{b_manifest[:help]}/)
  end

  it 'understands -- argument' do
    @args = ArgParser.new(a_manifest)
    mode = @args.parse!(%w[-- --mode])['mode']
    mode.count.must_equal(1)
    mode.value.first.must_equal(mode.default)
  end
end

describe 'Multiple argumented options w/default value' do
  before do
    @args = ArgParser.new(a_manifest)
  end

  it 'reads them and gives out values in order' do
    @args.parse!(%w[--mode second -m first -msecond -- -])
    @args['mode'].value.must_equal(%w[second first second])
  end

  it 'doesn''t validate unknown value' do
    lambda {
      @args.parse!(%w[--mode second -m foo -msecond -])
    }.must_raise(ExitStub).status.must_equal(2)
  end

  it 'doesn''t understand unknown options' do
    lambda {
      @args.parse!(%w[--mode second -abm foo -m first -- -])
    }.must_raise(ExitStub).status.must_equal(2)
  end
end

describe 'required option' do
  before do
    @b_manifest = a_manifest.merge({
      :options => (a_manifest[:options] + [{
          :names => %w[r required legacy-required],
          :required => true,
          :multiple => true
        }])
    })
    @args = ArgParser.new(@b_manifest)
  end

  it 'is really not optional' do
    e = lambda { @args.parse!(%w[-- file]) }.must_raise(ExitStub)
    e.status.must_equal(2)
  end

  it 'is actually multiple too' do
    @args.parse!(%w[-rrrrr --legacy-required --required -r -- file])
    @args['required'].count.must_equal(8)
  end

  it 'lives with an optional one' do
    @args.parse!(%w[--mode first -rmsecond])
    @args['required'].count.must_equal(1)
  end
end

describe 'input argument' do
  before do
    @b_manifest = a_manifest.merge({
      :arguments => (a_manifest[:arguments] + [{
          :name => 'file2'
        }])
    })
    @args = ArgParser.new(@b_manifest)
  end

  it 'terminates if name used as an option' do
    lambda { @args.parse!(%w[--file2 --]) }.must_raise(ExitStub)
  end

  it 'survives second optional argument' do
    @args.parse!(%w[file2])
    @args['file'].value.must_equal('file2')
    @args['file2'].value.must_equal(@args['file2'].default)
  end
end

describe 'optional tiny features' do
  before do
    @b_manifest = a_manifest.merge({
      :options => (a_manifest[:options] + [{
          :names => ['a', 'aaaaa'],
          :multiple => true,
          :param => 'arg'
        }])
    })
    @args = ArgParser.new(@b_manifest)
  end

  it 'allows to get value as string' do
    @args.parse!(%w[--aaaaa foo])
    "#{@args['aaaaa']}".must_equal('foo')
    @args.parse!(%w[--aaaaa foo -abar])
    "#{@args['aaaaa']}".must_equal('foo, bar')
  end
end
