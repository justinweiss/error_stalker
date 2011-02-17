source "http://rubygems.org"

# Specify your gem's dependencies in exceptionl.gemspec
gemspec

group :server do
  gem 'sinatra', '~>1.1.2'
  gem 'vegas', '~>0.1.8'
  gem 'thin', '~>1.2.7'
end

group :mongoid_store do
  gem 'mongoid', '2.0.0.beta.20'
end

group :test do
  gem 'rack-test', '~>0.5.7'
  gem 'mocha', '~>0.9.10'
end

group :lighthouse_reporter do
  gem 'lighthouse-api', '2.0'
  gem 'addressable', '~>2.2.2'
end

group :email_sender do
  gem 'mail', '~>2.2.15'
end

gem 'json', '1.4.6', :platforms => :ruby_18
