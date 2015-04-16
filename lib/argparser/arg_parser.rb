# coding: utf-8

class ArgParser
  include Tools
  include DefaultParser

  # Output messages used in the #terminate method
  OUT_VERSION = '%s%s %s'
  OUT_COPYRIGHT = 'Copyright (C) %s'
  OUT_LICENSE = 'License: %s'
  OUT_HOMEPAGE = '%s home page: %s'
  OUT_BUGS = 'Report bugs to: %s'
  OUT_MANIFEST_EXPECTED = 'Property expected through the manifest: %s'
  OUT_MULTIPLE_INPUTS = 'Multiple input argument not allowed in the middle: %s'
  OUT_MULTIPLE_NAMES = 'Multiple names for the input argument: %s'
  OUT_OPTION_NULL = 'Empty name for option'
  OUT_REQUIRED = 'Required input argument after optional one: %s'
  OUT_REQUIRED_DEFAULT = 'Required option has default value: %s'
  OUT_UNEXPECTED_ARGUMENT = 'Unexpected argument: %s'
  OUT_UNKNOWN_OPTION = 'Unknown option: %s'
  OUT_OPTION_ARGUMENT_EXPECTED = 'Expected argument for the option: %s'
  OUT_SINGLE_OPTION = 'Multiple options not allowed: %s'
  OUT_OPTION_EXPECTED = 'Expected option: %s'
  OUT_ARGUMENT_EXPECTED = 'Expected argument: %s'
  OUT_UNIQUE_NAME = 'Option name should be unique: %s'
  OUT_INVALID_OPTION = 'Invalid value for option: %s'
  OPT_ENOUGH  = '--'
  CAPTION_OPTIONS = 'OPTIONS:'
  CAPTION_ARGUMENTS = 'ARGUMENTS:'

  # These options don't display their synopsis and given for free unless
  # explicitly specified in the manifest.
  OPTS_RESERVED = [{:func => :printed_help,
                    :help => 'Print this help and exit.',
                    :names=> 'help'},
                   {:func => :printed_version,
                    :help => 'Print version and exit.',
                    :names=> 'version'}]

  attr_reader :program    # Program name, REQUIRED
  attr_reader :package    # Set to nil if there's no package
  attr_reader :version    # Follow semantic versioning rules, REQUIRED
  attr_reader :copyright  # '2015 Somebody, Inc.',
  attr_reader :license    # Give license headline
  attr_reader :info       # Set additional lines that would follow license
  attr_reader :bugs       # Address to post bug reports
  attr_reader :homepage   # Package or, if absent, program's home page
  attr_reader :synopsis   # Print this if present or construct from options
  attr_reader :help       # Print this if present or construct from options
  attr_reader :options    # Array of options/arguments,
                          # see ArgParser::Option class' attr_readers

  # Returns option by any of its names given
  def [](name)
    options.find{|o| o.names.include?(name)}
  end

  # Returns array of input args in order
  def arguments
    options.select{|o| o.input}
  end

  def get_argument(name)
    (i = self[name]) && i.input ? i : nil
  end

  def get_opt(name)
    (i = self[name]) && i.input ? nil : i
  end

  def opts
    options.select{|o| !o.input}
  end

  def initialize(manifest)
    manifest = (safe_return('$config.manifest') || {}).merge(manifest)
    hash2vars!(manifest)
    @options = (manifest[:options] || manifest['options'] || []).
      map {|o| o.kind_of?(Option) ? o : Option.new(o)}
  end

  def terminate(code, str)
    s = StringIO.new
    s.puts(printed_synopsis) if code != 0
    s.puts(str[-1] == "\n" ? str.chop : str)
    on_exit(code, s.string)
  end

  def on_exit(code, message)
    (code == 0 ? $stdout : $stderr).print(message)
    exit(code)
  end

  def printed_version
    str = StringIO.new
    pk = (pk = @package) ? " (#{pk})" : ''
    str.puts(OUT_VERSION % [program, pk, version])
    str.puts(OUT_COPYRIGHT % copyright) if copyright
    str.puts(OUT_LICENSE % license) if license
    str.string
  end

  def printed_help
    str = StringIO.new
    str.puts(printed_synopsis)
    str.puts(info) if info
    if help
      str.puts(help)
    else
      unless (os = opts).empty?
        str.puts(CAPTION_OPTIONS)
        os.each {|o| str.puts(o.printed_help)}
      end
      OPTS_RESERVED.each do |res|
        r = Option.new(res)
        next if get_argument(r.name)
        str.puts(r.printed_help)
      end
      unless (os = arguments).empty?
        str.puts(CAPTION_ARGUMENTS)
        os.each {|o| str.puts(o.printed_help)}
      end
    end
    str.puts(OUT_BUGS % bugs) if bugs
    str.puts(OUT_HOMEPAGE % [(package||program), homepage]) if homepage
    str.string
  end

  def printed_synopsis
    s = synopsis ||
      (options.select{|o| !o.input} + arguments).map{|o| o.synopsis}.join(' ')
    "Usage: #{program} #{s}"
  end
end
