# argparser gem TODO list

## More sophisticated output of printed_help
````ruby
  term_width = ENV['COLUMNS'] || `tput columns` || 80
  width = opts.reduce(0){|max, o| (sz = o.first.size) > max ? sz : max}
  help_width = term_width - (width += 1)
  if help_width < 32...
````

## RDocs
