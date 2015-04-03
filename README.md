# argparser
Command line argument parser library, trying to follow POSIX and GNU guidelines.

## Installation
`gem install argparser`, as usual.

## Usage by example
Suppose there's a file named `example.rb` like this:
````ruby
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
````

Now, let's look at the output of example given in various cases.

`$ ruby example.rb` is unsufficient:
````
example.rb [-m, --mode first|second|third]... file
Expected argument: file
````

`$ ruby example.rb --help` helps:
````
example.rb [-m, --mode first|second|third]... file
[-m, --mode first|second|third]...
  Example mode.
  Defaults to: first
[--help]
  Print this help and exit.
[--version]
  Print version and exit.
file
  Filename or - for stdin.
````

`$ echo "content" | ruby example.rb -` does the trick:
````
["first"]
content
````

`$ echo "content" | ruby example.rb --mode fourth -` oopses:
````
example.rb [-m, --mode first|second|third]... file
Invalid option: m
````

`$ echo "content" | ruby example.rb -abcm first -`:
````
example.rb [-m, --mode first|second|third]... file
Unknown option: a
````

## Consider more rules
* `--help` and `--version` options provided for free unless specified.
* printed synopsys provided for free unless specified
* `:default` used if option has :argument and no value given, lowest priority
* `:env  => 'ENV_VAR'` to pick default value from ENV, high priority
* `:eval => 'ruby expr'` to pick default from eval(...), useful for read defaults from config files, so it has low priority
* `--`-argument honored

## Documentation
This README is all i could say in a rush. No other documentation provided at this moment, see the sources.

## If you've found a bug or drawback
Don't hesistate to leave a report.

## License
MIT for now.

## TODO
* Go steal milk for the hazards applied.
