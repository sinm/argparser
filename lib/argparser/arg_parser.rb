# coding: utf-8

class ArgParser
  include Tools

  # Output templates used for the #terminate(0) call
  OUT_VERSION   = '%s%s %s'
  OUT_COPYRIGHT = 'Copyright (C) %s'
  OUT_LICENSE   = 'License: %s'
  OUT_HOMEPAGE  = '%s home page: %s'
  OUT_BUGS      = 'Report bugs to: %s'
  OUT_OPTIONS   = 'OPTIONS:'
  OUT_ARGUMENTS = 'ARGUMENTS:'

  # Templates used for the terminate(2) call
  TRM_UNEXPECTED_ARGUMENT       = 'Unexpected argument: %s'
  TRM_UNKNOWN                   = 'Unknown option: %s'
  TRM_OPTION_ARGUMENT_EXPECTED  = 'Expected parameter for the option: %s'
  TRM_EXPECTED                  = 'Expected required argument/option: %s'
  TRM_INVALID_OPTION            = 'Invalid value for the argument/option: %s'

  OPT_ENOUGH  = '--'

  # These options don't display their synopsis and given for free unless
  # explicitly specified in the manifest.
  OPTS_RESERVED = [{:func => :printed_help,
                    :help => 'Print this help and exit.',
                    :name => 'help'},
                   {:func => :printed_version,
                    :help => 'Print version and exit.',
                    :name => 'version'}]

  attr_reader :program    # Program name, REQUIRED
  attr_reader :package    # Set to nil if there's no package
  attr_reader :version    # Follow semantic versioning rules, REQUIRED
  attr_reader :copyright  # Like '2015 Somebody, Inc.',
  attr_reader :license    # Give license headline
  attr_reader :info       # Program info string
  attr_reader :bugs       # Address to post bug reports
  attr_reader :homepage   # Package or, if absent, program's home page
  attr_reader :synopsis   # Build from options if not given
  attr_reader :help       # Build from options if not given
  attr_reader :arguments  # Array of arguments
  attr_reader :options    # Array of options
                          # see ArgParser::Argument/Option classes attr_readers

  class << self
    def manifest=(manifest)
      @@manifest = manifest
    end

    def manifest
      @@manifest ||= {}
    end
  end

  # Returns option by any of its names given
  def [](name)
    get_argument(name) || get_option(name)
  end

  def all
    options + arguments
  end

  def get_argument(name)
    arguments.find{|a| a.name == name}
  end

  def get_option(name)
    options.find{|o| o.names.include?(name)}
  end

  def initialize(manifest)
    hash2vars(ArgParser.manifest.merge(manifest))
    @arguments =
      (@arguments || []).map {|o| o.kind_of?(Argument) ? o : Argument.new(o)}
    @options =
      (@options || []).map   {|o| o.kind_of?(Option)   ? o : Option.new(o)}
    _check_manifest
  end

  # Uses ARGV by default, but you may supply your own arguments
  # It exits if bad arguments given or they aren't validated.
  def parse(argv = ARGV)
    all.each(&:reset)
    _check_manifest

    OPTS_RESERVED.each do |res|
      next if !argv.include?("--#{res[:name]}") || self[res[:name]]
      terminate(0, send(res[:func]))
    end

    args = argv.dup
    enough = false
    while (a = args.shift)
      if a == OPT_ENOUGH
        enough = true
      elsif enough || (a =~ /^[^-]/) || (a == '-')
        _set_argument(a)
      elsif a =~ /^--(.+)/
        _set_long_option($1, args)
      elsif a =~ /^-([^-].*)/
        _set_short_options($1, args)
      else
        terminate(2, TRM_UNKNOWN % a)
      end
    end

    all.each { |o|
      o.set_default
      terminate(2, (TRM_EXPECTED % o.name)) if o.required && !o.value?
    }

    all.each { |o|
      terminate(2, TRM_INVALID_OPTION % o.name) unless o.valid?(self)
    }

    all.select(&:value?).each {|o| yield(o.name, o.value)} if block_given?

    self
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
      unless options.empty?
        str.puts(OUT_OPTIONS)
        options.each {|o| str.puts(o.printed_help)}
      end
      OPTS_RESERVED.each do |res|
        r = Option.new(res)
        next if get_argument(r.name)
        str.puts(r.printed_help)
      end
      unless arguments.empty?
        str.puts(OUT_ARGUMENTS)
        arguments.each {|a| str.puts(a.printed_help)}
      end
    end
    str.puts(OUT_BUGS % bugs) if bugs
    str.puts(OUT_HOMEPAGE % [(package||program), homepage]) if homepage
    str.string
  end

  def printed_synopsis
    "Usage: #{program} #{synopsis || all.map{|o| o.synopsis}.join(' ')}"
  end

  private

  def _check_manifest
    {:program => program, :version => version}.each do |k, v|
      raise ManifestError, (ERR_MANIFEST_EXPECTED % k) if v.to_s.strip.empty?
    end

    arguments[0..-2].each do |i|
      raise ManifestError, (ERR_MULTIPLE_INPUTS % i.name) if i.multiple
    end
    opt = arguments.index{|i|  !i.required} || arguments.size
    req  = arguments.rindex{|i| i.required} || 0
    raise ManifestError, (ERR_REQUIRED % arguments[req].name) if req > opt

    names = all.map(&:names).flatten
    raise ManifestError, ERR_UNIQUE_NAME if names.size != names.uniq.size
  end

  def _set_argument(a)
    terminate(2, TRM_UNEXPECTED_ARGUMENT % a) unless
     (input = arguments.find{|i| !i.value || i.multiple})
    input.add_value(a)
  end

  def _set_long_option(a, tail)
    terminate(2, TRM_UNKNOWN % a) unless a.size > 1 && (o = get_option(a))
    terminate(2, TRM_OPTION_ARGUMENT_EXPECTED % a) if o.param && tail.empty?
    o.add_value(o.param ? tail.shift : nil)
  end

  def _set_short_options(a, tail)
    a.chars.each_with_index do |char, index|
      terminate(2, TRM_UNKNOWN % char) unless (option = get_option(char))
      if !option.param
        option.add_value(nil)
      elsif a.size-1 == index
        terminate(2, TRM_OPTION_ARGUMENT_EXPECTED % char) if tail.empty?
        option.add_value(tail.shift)
      else
        option.add_value(a[index+1..-1])
        break
      end
    end
  end
end
