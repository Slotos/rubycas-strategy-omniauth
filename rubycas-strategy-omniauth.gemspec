# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rubycas-strategy-omniauth/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Dmitriy Soltys"]
  gem.email         = ["slotos@gmail.com"]
  gem.description   = %q{OmniAuth strategy adapter for rubycas-server}
  gem.summary       = %q{Provides ability to authenticate users against oauth services as part of your CAS SSO functionality}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rubycas-strategy-omniauth"
  gem.require_paths = ["lib"]
  gem.version       = CASServer::Strategy::OmniAuth::VERSION

  gem.add_dependency "sequel"
  gem.add_dependency "rubycas-server"
  gem.add_dependency "typhoeus"
  gem.add_dependency "addressable"

  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rack-test"
  gem.add_development_dependency "omniauth-facebook"
end
