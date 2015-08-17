# coding: utf-8

class ArgParser
  class Option < Argument
    # These attrs are from the manifest that is applied through constructor
    attr_reader :param  # Parameter name, if any
    # Returns first name as a 'default' one when several names given
    def name
      @name ||= names.first
    end

    alias argument param

    # Names of an option (short, long, etc.)
    def names
      @names ||= [@name]
    end

    def synopsis
      s = names.map{|n| n.size == 1 ? "-#{n}" : "--#{n}"}.join(', ')
      s << " #{param}" if param
      s = "[#{s}]" if !required
      s << '...' if multiple
      s
    end
  end
end
