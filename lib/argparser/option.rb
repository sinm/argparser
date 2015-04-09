# coding: utf-8
require 'argparser/tools'

class ArgParser
  class Option
    include Tools
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

    # Returns most lengthy name as a 'default' name of this option
    def name
      names.first
    end

    # Constructs option from Hash of properties (see attr_readers)
    def initialize(o_manifest)
      hash2vars!(o_manifest)
      @names = Array(names).map{|n|n.to_s.strip}.
        sort{|n1, n2| n1.size <=> n2.size}
      reset!
    end

    # Sets value. Do not use this directly
    def set_value(v)
      @count += 1
      multiple ? (@value << v).flatten! : @value = v
    end

    # Does option contain it's value?
    def value?
      multiple ? !value.compact.empty? : !!value
    end

    def to_s
      value
    end

    def synopsis
      if input
        s = name.dup
        s << '...' if multiple
        s = "[#{s}]" if !required
        s
      else
        s = names.map{|n| n.size == 1 ? "-#{n}" : "--#{n}"}.join(', ')
        s << " #{argument}" if argument
        s = "[#{s}]" if !required
        s << '...' if multiple
        s
      end
    end

    def validate!(parser)
      !validate || validate.call(self, parser)
    end

    def reset!
      @value = multiple ? [] : nil
      @count = 0
    end
  end
end
