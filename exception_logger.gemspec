# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "exception_logger/version"

Gem::Specification.new do |s|
  s.name        = "exception_logger"
  s.version     = ExceptionLogger::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Justin Weiss"]
  s.email       = ["jweiss@avvo.com"]
  s.homepage    = ""
  s.summary     = %q{Logs exceptions to a pluggable backend and/or a pluggable store}
  s.description = %q{Logs exceptions to a pluggable backend. Also provides a server for centralized exception logging using a pluggable data store.}

  s.rubyforge_project = "exception_logger"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
