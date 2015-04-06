# coding: utf-8
require 'argparser'
args= ArgParser.new( # Here goes the manifest.
  :program => 'example.rb', # Use additional properties like these:
  :version => '1.0',        #   :info, :copyright, :license,
  :options => [{            #   :package, :bugs, :homepage
    :names      => %w[m mode],
    :argument   => 'first|second|third',
    :default    => 'first',
    :multiple   => true,
    :help       => 'Example mode.',
    :validate   => (lambda {|this, parser|  # Validating value in-line
      possible = this.argument.split('|')
      this.value.select{|v| possible.include?(v)}.size == this.value.size })
  }, {
    :names      => 'file',
    :input      => true,
    :required   => true,
    :help       => 'Filename or - for stdin.',
    :validate   => (lambda {|this, parser|
      if this.value == '-'
        this.value = $stdin.read
      else
        parser.terminate(2, 'No such file') unless File.exists?(this.value)
        this.value = File.read(this.value)
      end
      true })
  }]
).parse!  # Uses ARGV by default, you may supply your own arguments.
          # It exits if bad arguments given or they aren't validated.

puts args['mode'].value.inspect # So we could use our options...
puts args['file'].value         # Prints contents of a file
