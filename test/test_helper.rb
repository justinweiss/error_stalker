require 'test/unit'
require 'exceptionl'
require 'mail'

Mail.defaults do
  delivery_method :test
end
