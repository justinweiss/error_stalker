require 'test/unit'
require 'exceptionl'
require 'mail'
require 'exceptionl/server'

Mail.defaults do
  delivery_method :test
end
