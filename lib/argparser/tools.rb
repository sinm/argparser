# coding: utf-8

class ArgParser
  # Aux tools intented to include into a class
  module Tools

    # Sets self state from a hash given
    def hash2vars!(hash)
      hash.each do |k, v|
        next unless self.respond_to?(k)
        instance_variable_set("@#{k}", v)
      end
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
      eval(str)
    rescue NameError, NoMethodError
      nil
    end
  end
end
