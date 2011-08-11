require 'test/unit'
require 'error_stalker'
require 'mail'
require 'error_stalker/server'

Mail.defaults do
  delivery_method :test
end
