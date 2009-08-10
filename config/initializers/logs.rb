# Sets up logging for 404 errors. Usage:

# ERROR_404_LOG.warn request.url

_file = File.open( "#{RAILS_ROOT}/log/error_404.log", 'a' )
_file.sync = true
ERROR_404_LOG = Logger.new(_file)
