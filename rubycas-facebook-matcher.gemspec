# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rubycas-facebook-matcher/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Dmitriy Soltys"]
  gem.email         = ["slotos@gmail.com"]
  gem.description   = %q{Facebook-to-local user matching functionality for rubycas-server}
  gem.summary       = %q{Provides ability to authenticate users against Facebook oauth service as part of your CAS SSO functionality}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rubycas-facebook-matcher"
  gem.require_paths = ["lib"]
  gem.version       = CASServer::Matchers::Facebook::VERSION

  gem.add_dependency "sequel"
  gem.add_dependency "rubycas-server"
  gem.add_dependency "omniauth-facebook"
  gem.add_dependency "typhoeus"

  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rack-test"
end
