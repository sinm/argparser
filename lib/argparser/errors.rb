class ArgParser
  ERR_OPTION_NULL       = 'Empty name for an argument'
  ERR_MANIFEST_EXPECTED = 'Property expected through the manifest: %s'
  ERR_MULTIPLE_INPUTS   = 'Multi-value argument allowed only if last: %s'
  ERR_REQUIRED          = 'Required argument after optional one: %s'
  ERR_UNIQUE_NAME       = 'All option/argument names must be unique'
  class ManifestError < RuntimeError
  end
end
