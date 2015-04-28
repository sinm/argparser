# coding: utf-8

class ArgParser
  class Argument
    include Tools

    # These attrs are from the manifest that is applied through constructor
    attr_reader   :name
    attr_reader   :help     # Help string
    attr_reader   :validate # Proc(this, parser) to validate a value
    attr_reader   :default  # Value or proc to set default value
    attr_reader   :required # Required
    attr_reader   :multiple # May occur multiple times?

    # These attrs have their meaning after parsing was done
    attr_reader   :count    # Occucences
    attr_reader   :value    # Value (Array if multiple)

    # Just helper
    def names
      [name]
    end

    # Constructs from Hash of properties (see attr_readers)
    def initialize(o_manifest)
      hash2vars(o_manifest)
      reset
      raise ManifestError, ERR_OPTION_NULL if !name or name.strip.empty?
    end

    def synopsis
      s = name.dup
      s << '...' if multiple
      s = "[#{s}]" if !required
      s
    end

    # Adds value.
    def add_value(v)
      @count += 1
      multiple ? (@value = @value + Array(v)) : @value = v
      self
    end

    # Does option contain it's value?
    def value?
      @count > 0
    end

    # Returns value as string
    def to_s
      multiple ? value.map(&:to_s).join(', ') : value.to_s
    end

    def valid?(parser)
      !validate || validate.call(self, parser)
    end

    def reset
      @value = multiple ? [] : nil
      @count = 0
      self
    end

    def printed_help
      s = help || ''
      s << "\n\tDefaults to: #{get_default}" if default
      "%s\n\t%s" % [synopsis, s]
    end

    # Set value to default one if no value provided
    def set_default
      return self if !default || value?
      add_value(get_default)
    end

    # Get default value
    def get_default
      default.respond_to?(:call) ? default.call : default
    end
  end
end
