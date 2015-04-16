# coding: utf-8

class ArgParser
  # Aux tools intented to include into a class
  module Tools
    # Sets self state from a hash given
    def hash2vars!(hash)
      if hash.kind_of?(Hash) || (hash.respond_to?(:to_h) && (hash = hash.to_h))
        hash.each do |k, v|
          next unless self.respond_to?(k)
          instance_variable_set("@#{k}", v)
        end
      else
        raise 'Hash expected'
      end
      self
    end

    # Returns a hash of self state, packing all objects to hashes
    def to_hash
      instance_variables.reduce({}) { |hash, var|
        hash[var[1..-1]] = instance_variable_get(var)
        hash }
    end

    # Eval ruby code.
    # Returns result of Kernel.eval or nil if some errors occure
    def safe_return(str)
      # rubocop:disable Lint/Eval
      eval(str)
      # rubocop:enable Lint/Eval
    rescue NameError
      nil
    end

=begin Deep pack
    def to_hash(deep = true)
      instance_variables.reduce({}) { |hash, var|
        value = instance_variable_get(var)
        hash[var[1..-1]] = deep ? value_to_hash(value) : value
        hash }
    end

    private
    def value_to_hash value
      if value.respond_to?(:to_hash)
        (v = value.to_hash).kind_of?(Hash) ? v : {}
      elsif value.respond_to?(:to_a)
        (v = value.to_a).kind_of?(Array) ? v.map{|v| value_to_hash(v)} : []
      else
        value
      end
    end
=end
  end
end
