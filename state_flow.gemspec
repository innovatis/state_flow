# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "state_flow/version"

Gem::Specification.new do |s|
  s.name        = "state_flow"
  s.version     = StateFlow::VERSION
  s.authors     = ["Burke Libbey"]
  s.email       = ["burke@burkelibbey.org"]
  s.homepage    = ""
  s.summary     = "state thing"
  s.description = "state thing"
  s.summary     = "state thing"

  s.rubyforge_project = "state_flow"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

end
