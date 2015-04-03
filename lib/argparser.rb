
#__END__
module Tulz
  def hash2vars!(hash)
    hash.each do |k, v|
      next unless self.respond_to?(k)
      instance_variable_set("@#{k}", v)
    end
  end

  def to_hash
    instance_variables.reduce({}) { |hash, var|
      hash[var[1..-1]] = instance_variable_get(var)
      hash }
  end

  def safe_return(str)
    eval(str)
  rescue Exception
    # intentionally left blank
  end
end

class ArgParser
  include Tulz
  OUT_VERSION = '%s %s %s'
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
  INVALID_OPTION = 'Invalid option: %s'
  OPT_HELP    = 'help'
  OPT_VERSION = 'version'
  OPT_ENOUGH  = '--'

  class Option
    include Tulz
    attr_reader   :names    # Names of an option (short, long, etc.)
    attr_reader   :argument # Name of an argument, if present
    attr_reader   :help     # Help string for an option
    attr_reader   :validate # Lambda(option, parser) to validate an option
    attr_reader   :default  # Default value for an option
    attr_reader   :input    # Option is an input argument
    attr_reader   :required # Option required
    attr_reader   :multiple # Option may occure multiple times
    attr_reader   :count    # Option occucences
    attr_reader   :env      # Default option set by this ENV VAR, if any
    attr_reader   :eval     # Default option set by this eval,
                            # superseded by :env, if any
                            # So, in order: value - env - eval - default
    attr_accessor :value    # Values of an option, Array if multiple

    def name
      names.first
    end

    def initialize(o_manifest)
      hash2vars!(o_manifest)
      @names = Array(names).map(&:to_s).sort{|n1, n2| n1.size <=> n2.size}
      @value = [] if multiple
      @count = 0
    end

    def set_value(v)
      @count += 1
      multiple ? (@value << v).flatten! : @value = v
    end

    def value?
      multiple ? !value.compact.empty? : !!value
    end

    def to_s
      str = ''
      str += (count     ? count.to_s : ' ')
      str += (argument  ? 'A' : ' ')
      str += (validate  ? 'V' : ' ')
      str += (default   ? 'D' : ' ')
      str += (input     ? 'I' : ' ')
      str += (required  ? 'R' : ' ')
      str += (multiple  ? 'M' : ' ')
      str += " #{names.inspect}"
      str += " #{value.inspect}" if value
    end

    def synopsis
      if input
        s = name.dup
        s << '...' if multiple
        s = "[#{s}]" if !required
        return s
      else
        s = names.map{|n| n.size == 1 ? "-#{n}" : "--#{n}"}.join(', ')
        s << " #{argument}" if argument
        s = "[#{s}]" if !required
        s << '...' if multiple
        return s
      end
    end

    def validate!(parser)
      !validate || validate.call(self, parser)
    end
  end

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
  attr_reader :options    # Options in a hash,
                          # see ArgParser::Option class' attr_reader

  def [](name)
    options.find{|o| o.names.include?(name)}
  end

  # Returns array of input args in order
  def inputs
    options.select{|o| o.input}
  end

  def initialize(manifest)
    manifest = {
      :options    => []
    }.merge(safe_return('$config.manifest') || {}).merge(manifest)
    hash2vars!(manifest)
    @options = (manifest[:options] || manifest['options'] || {}).map do |o|
      Option.new(o)
    end
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

  def parse!(arguments = ARGV)
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
        if name.strip.empty?
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

    [OPT_VERSION, OPT_HELP].each { |o|
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
        if $1.size > 1 && option = self[$1]
          if option.argument
            if args.empty?
              terminate(2, $stderr.puts(OUT_OPTION_ARGUMENT_EXPECTED % a))
            end
            option.set_value(args.shift)
          else
            option.set_value(nil)
          end
        else
          terminate(2, OUT_UNKNOWN_OPTION % a)
        end
      elsif a =~ /^-([^-].*)/ # short option, may combine and has an arg at end
        (opts = $1).chars.to_a.each_with_index do |char, index|
          if (option = self[char])
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
            terminate(2, OUT_UNKNOWN_OPTION % a)
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
      next if o.validate!(self)
      terminate(2, INVALID_OPTION % o.name)
    }
    self
  end

  def terminate(code, str = nil)
    stream = code == 0 ? $stdout : $stderr
    stream.puts(printed_synopsis) if code != 0
    if str
      stream.print(str)
      stream.puts() unless str[-1] == "\n"
    end
    exit!(code)
  end

  def printed_version
    pk = (pk = @package) ? "(#{pk})" : ''
    str = ''
    str << (OUT_VERSION    % [@program, pk, @version]) + "\n"
    str << (OUT_COPYRIGHT  % @copyright) + "\n"
    str << (OUT_LICENSE    % @license) + "\n"
  end

  def printed_help
    str = printed_synopsis + "\n"
    str << info + "\n\n" if info
    if help
      str << help + "\n"
    else
      opts = []
      options.select{|o| !o.input}.each do |o|
        next unless h = o.help
        h << "\n\tDefaults to: #{o.default}" if o.default
        opts << [o.synopsis, h]
      end
      inputs.each do |i|
        next unless i.help
        help = i.help
        help << "\n\tDefaults to: #{i.default}" if i.default
        opts << [i.synopsis, help]
      end
      opts.each do |o|
        str << "%s\n\t%s\n" % [o.first, o.last]
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

  if __FILE__ == $0 # Some selftests
    $stdout.sync = true
    $stderr.sync = true
    args = ArgParser.new(
      :version    => '00',
      :program    => 'exec',
      :info       => 'executes command over a group of servers',
      :options    => [{
        :names    => 'group',
        :input    => true,
        :required => true,
        :help     => 'Name of a group'
      },{
        :names    => 'command',
        :input    => true,
        :required => true,
        :multiple => true,
        :help     => 'command to execute'
      }]
    ).parse!(%w[--help])

    puts args.options.map(&:to_s).join("\n")
    puts 'OK!'
  end

end # class
