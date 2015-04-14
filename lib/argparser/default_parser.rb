# coding: utf-8
#

class ArgParser
  module DefaultParser
    # Uses ARGV by default, but you may supply your own arguments
    # It exits if bad arguments given or they aren't validated.
    def parse!(arguments = ARGV)
      options.each(&:reset!)
      _check_manifest!

      OPTS_RESERVED.each { |o|
        next unless arguments.include?("--#{o}")
        self[o].set_value(nil)
        self[o].validate!(self)
        self[o].reset! # If it didn't terminate while validating
      }

      args = arguments.dup
      enough = false
      while (a = args.shift)
        if a == OPT_ENOUGH
          enough = true
        elsif enough || (a =~ /^[^-]/) || (a == '-')
          _set_argument!(a)
        elsif a =~ /^--(.+)/
          _set_long_option!(a, args)
        elsif a =~ /^-([^-].*)/
          _set_short_options!(a, args)
        else
          terminate(2, OUT_UNKNOWN_OPTION % a)
        end
      end

      options.each { |o|
        o.set_default!
        o.on_first_error {|msg| terminate(2, msg)}
      }

      options.each { |o|
        terminate(2, OUT_INVALID_OPTION % o.name) unless o.validate!(self)
      }

      self
    end

    private

    def _set_argument!(a)
      if (input = inputs.find{|i| !i.value || i.multiple})
        input.set_value(a)
      else
        terminate(2, OUT_UNEXPECTED_ARGUMENT % a)
      end
    end

    def _set_long_option!(a, tail)
      a = a[2..-1]
      if a.size > 1 && (option = self[a]) && !option.input
        if option.argument
          terminate(2, OUT_OPTION_ARGUMENT_EXPECTED % a) if tail.empty?
          option.set_value(tail.shift)
        else
          option.set_value(nil)
        end
      else
        terminate(2, OUT_UNKNOWN_OPTION % $1)
      end
    end

    def _set_short_options!(a, tail)
      (a = a[1..-1]).chars.each_with_index do |char, index|
        unless (option = self[char]) && !option.input
          terminate(2, OUT_UNKNOWN_OPTION % char)
        end
        if option.argument
          if a.size-1 == index
            terminate(2, OUT_OPTION_ARGUMENT_EXPECTED % char) if tail.empty?
            option.set_value(tail.shift)
          else
            option.set_value(a[index+1..-1])
            break
          end
        else
          option.set_value(nil)
        end
      end
    end

    def _check_manifest!
      {:program => program, :version => version}.each do |k, v|
        terminate(2, OUT_MANIFEST_EXPECTED % k) if !v || v.to_s.strip.empty?
      end

      is = inputs
      is.each_with_index do |i, index|
        if index < is.length-1 && i.multiple
          terminate(2, OUT_MULTIPLE_INPUTS % i.name)
        elsif i.names.size > 1
          terminate(2, OUT_MULTIPLE_NAMES % i.name)
        end
      end
      opt = is.index{|i| !i.required} || is.size
      req  = is.rindex{|i| i.required} || 0
      terminate(2, OUT_REQUIRED % is[req].name) if req > opt

      names = {}
      options.each do |option|
        option.names.each do |name|
          terminate(2, OUT_UNIQUE_NAME % name) if names.has_key?(name)
          names[name] = option
        end
      end
    end
  end
end
