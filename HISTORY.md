# 2.0.1
2015-04-28

* moved rubocop to Gemfile, it prevents build on MRI 1.8

# 2.0.0
2015-04-28 Holidays

* All exclamation marks removed from method names
* `Option/Argument#set_value` renamed to `#add_value`
* `Option/Argument#add_value`, `set_default` and `#reset` now return `self`
* `Option/Argument#value` now is read-only
* `Option/Argument#value?` now returns true in case of parsed option w/o param
* Block(name, value) in `#parse`
* Major version changed due to extensive renamings and removals
* Whitespace in option names no longer stripped
* Separate classes for options and arguments
* `Option#argument` renamed to `Option#param`
* `Option#eval` and `Option#env` settings removed as they aren't secure, use `Option#default`, which now may be a proc/lambda
* `ArgParser.manifest=` added, which merges with manifest supplied through `ArgParser.new`
* `ArgParser.new` raises `ManifestError` instead of late `exit(2)` in `ArgParser#parse` while checking manifest
* `DefaultParser` module removed and `#parse!` method merged back into `ArgParser`

# 1.0.1
2015-04-14

* Some minor fixes and refactorings
* MRI-1.8, jruby-1.8-mode support

# 1.0.0
2015-04-03

* First public release
