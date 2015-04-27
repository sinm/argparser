# coding: utf-8

class ArgParser
  class Argument
    include Tools
    attr_reader   :name
    attr_reader   :help     # Help string
    attr_reader   :validate # Proc(this, parser) to validate a value
    attr_reader   :default  # Value or proc to set default value
    attr_reader   :required # Required
    attr_reader   :multiple # May occur multiple times?

    attr_reader   :count    # Occucences after parsing was done
    attr_accessor :value    # Value (Array if multiple) after parsing was done

    # Constructs from Hash of properties (see attr_readers)
    def initialize(o_manifest)
      hash2vars!(o_manifest)
      reset!
      raise ManifestError, ERR_OPTION_NULL if !name or name.strip.empty?
    end

    def synopsis
      s = name.dup
      s << '...' if multiple
      s = "[#{s}]" if !required
      s
    end

    # Sets value. Do not use this directly
    def set_value(v)
      @count += 1
      multiple ? (@value << v).flatten! : @value = v if !v.nil?
    end

    # Does option contain it's value?
    def value?
      multiple ? !value.empty? : !!value
    end

    # Returns value as string
    def to_s
      multiple ? value.map(&:to_s).join(', ') : value.to_s
    end

    def validate!(parser)
      !validate || validate.call(self, parser)
    end

    def reset!
      @value = multiple ? [] : nil
      @count = 0
    end

    def printed_help
      s = help || ''
      s << "\n\tDefaults to: #{get_default}" if default
      "%s\n\t%s" % [synopsis, s]
    end

    # Set value to default one if no value provided
    def set_default!
      return if !default || value?
      set_value(get_default)
    end

    # Get default value
    def get_default
      default.respond_to?(:call) ? default.call : default
    end
  end
end
