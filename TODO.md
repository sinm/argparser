# argparser gem TODO list

5. Testing bash and rb scripts
4. CPU Profiling
3. + remove eval
2. More sophisticated output of printed_help
````ruby
  term_width = ENV['COLUMNS'] || `tput columns` || 80
  width = opts.reduce(0){|max, o| (sz = o.first.size) > max ? sz : max}
  help_width = term_width - (width += 1)
  if help_width < 32...
````
1. RDocs
