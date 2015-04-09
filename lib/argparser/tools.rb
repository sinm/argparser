# coding: utf-8

class ArgParser
  module Tools
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
    rescue NameError, NoMethodError
      nil
    end
  end
end
