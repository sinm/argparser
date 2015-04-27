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

    # Returns a hash of self state
    def to_hash
      instance_variables.reduce({}) { |hash, var|
        hash[var[1..-1]] = instance_variable_get(var)
        hash }
    end
  end
end
