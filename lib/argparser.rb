# coding: utf-8
require 'argparser/tools'
require 'argparser/option'

class ArgParser
  include Tools

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

  # These options don't display their synopsis and given for free unless
  # explicitly specified in the manifest.
  OPT_HELP    = 'help'
  OPT_VERSION = 'version'
  OPTS_RESERVED = [OPT_HELP, OPT_VERSION]

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
  attr_reader :options    # Array of options,
                          # see ArgParser::Option class' attr_readers

  # Returns option by any of its names given
  def [](name)
    options.find{|o| o.names.include?(name)}
  end

  # Returns array of input args in order
  def inputs
    options.select{|o| o.input}
  end

  def initialize(manifest)
    manifest = (safe_return('$config.manifest') || {}).merge(manifest)
    hash2vars!(manifest)
    @options = (manifest[:options] || manifest['options'] || []).
      map {|o| o.kind_of?(Option) ? o : Option.new(o)}
    if !self['help']
      options << Option.new(:names    => OPT_HELP,
                            :help     => 'Print this help and exit.',
                            :validate => (lambda { |o, p|
                              return true if o.count < 1
                              p.terminate(0, p.printed_help) }))
    end
    if !self['version']
      options << Option.new(:names    => OPT_VERSION,
                            :help     => 'Print version and exit.',
                            :validate => (lambda { |o, p|
                              return true if o.count < 1
                              p.terminate(0, p.printed_version) }))
    end
  end

  # Uses ARGV by default, but you may supply your own arguments
  # It exits if bad arguments given or they aren't validated.
  def parse!(arguments = ARGV)
    @options.each(&:reset!)

    {:program => @program, :version => @version}.each do |k, v|
      if !v || v.to_s.strip.empty?
        terminate(2, OUT_MANIFEST_EXPECTED % k)
      end
    end

    is = inputs
    is.each_with_index do |i, index|
      if index < is.length-1 and i.multiple
        terminate(2, OUT_MULTIPLE_INPUTS % i.name)
      end
      if i.names.size > 1
        terminate(2, OUT_MULTIPLE_NAMES % i.name)
      end
    end
    first_optional = is.index{|i| !i.required} || is.size
    last_required  = is.rindex{|i| i.required} || 0
    if last_required > first_optional
      terminate(2, OUT_REQUIRED % is[last_required].name)
    end

    names = {}
    options.each do |option|
      option.names.each do |name|
        if name.empty?
          terminate(2, OUT_OPTION_NULL)
        end
        if names.has_key?(name)
          terminate(2, OUT_UNIQUE_NAME % name)
        end
        names[name] = option
      end
      if option.required && option.default
        terminate(2, OUT_REQUIRED_DEFAULT % option.name)
      end
    end

    OPTS_RESERVED.each { |o|
      next unless arguments.include?("--#{o}")
      o = self[o]
      o.set_value(nil)
      o.validate!(self)
    }

    args = arguments.dup
    enough = false
    while (a = args.shift)
      if a == OPT_ENOUGH
        enough = true
      elsif enough || (a =~ /^[^-]/) || (a == '-') # input argument
        if (input = inputs.find{|i| !i.value || i.multiple})
          input.set_value(a)
        else
          terminate(2, OUT_UNEXPECTED_ARGUMENT % a)
        end
      elsif a =~ /^--(.+)/ # long option
        if $1.size > 1 && (option = self[$1]) && !option.input
          if option.argument
            if args.empty?
              terminate(2, OUT_OPTION_ARGUMENT_EXPECTED % a)
            end
            option.set_value(args.shift)
          else
            option.set_value(nil)
          end
        else
          terminate(2, OUT_UNKNOWN_OPTION % $1)
        end
      elsif a =~ /^-([^-].*)/ # short option, combines, trailing argument
        (opts = $1).chars.to_a.each_with_index do |char, index|
          if (option = self[char]) && !option.input
            if option.argument
              if opts.size-1 == index
                if args.empty?
                  terminate(2, OUT_OPTION_ARGUMENT_EXPECTED % a)
                else
                  option.set_value(args.shift)
                end
              else
                option.set_value(opts[index+1..-1])
                break
              end
            else
              option.set_value(nil)
            end
          else
            terminate(2, OUT_UNKNOWN_OPTION % char)
          end
        end
      else
        terminate(2, OUT_UNKNOWN_OPTION % a)
      end
    end

    options.each do |option|
      if  !option.value? && (option.argument || option.input) &&
          ((option.env      && (e = ENV[option.env])) ||
          (option.eval      && (e = safe_return(option.eval))) ||
          (!!option.default && (e = option.default)))
            option.set_value(e)
      end
      if !option.multiple && option.count > 1
        terminate(2, OUT_SINGLE_OPTION % option.name)
      elsif option.required && option.count < 1
        if option.input
          terminate(2, OUT_ARGUMENT_EXPECTED % option.name)
        else
          terminate(2, OUT_OPTION_EXPECTED % option.name)
        end
      end
    end

    options.each { |o|
      terminate(2, OUT_INVALID_OPTION % o.name) unless o.validate!(self)
    }

    self
  end

  def terminate(code, str)
    s = ''
    s << printed_synopsis << "\n" if code != 0
    s << str
    s << "\n" unless str[-1] == "\n"
    stream = code == 0 ? $stdout : $stderr
    stream.print(s)
    on_exit(code, s)
  end

  def on_exit(code, message)
    exit(code)
  end

  def printed_version
    pk = (pk = @package) ? " (#{pk})" : ''
    str = ''
    str << (OUT_VERSION    % [@program, pk, @version]) << "\n"
    str << (OUT_COPYRIGHT  % @copyright) << "\n" if @copyright
    str << (OUT_LICENSE    % @license) << "\n" if @license
    str
  end

  def printed_help
    str = printed_synopsis << "\n"
    str << info << "\n\n" if info
    if help
      str << help << "\n"
    else
      (options.select{|o| !o.input} + inputs).each do |o|
        next unless h = o.help
        h << "\n\tDefaults to: #{o.default}" if o.default
        str << "%s\n\t%s\n" % [o.synopsis, h]
      end
      # term_width = ENV['COLUMNS'] || `tput columns` || 80
      # name_width = opts.reduce(0){|max, o| (sz = o.first.size) > max ? sz : max}
      # help_width = term_width - (name_width += 1)
      # if help_width < 32...
    end
    str << (OUT_BUGS % @bugs) + "\n" if bugs
    what = @package || @program
    str << (OUT_HOMEPAGE % [what, @homepage]) + "\n" if homepage
    str
  end

  def printed_synopsis
    s = synopsis ||
      (options.select{|o| !o.input} + inputs).map{|o| o.synopsis}.join(' ')
    "#{program} #{s}"
  end
end
