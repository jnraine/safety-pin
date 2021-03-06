# -*- encoding: utf-8 -*-
require File.expand_path('../lib/safety_pin/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jordan Raine"]
  gem.email         = ["jnraine@gmail.com"]
  gem.description   = %q{An easy-to-use JCR connector for JRuby}
  gem.summary       = %q{JCR connector for JRuby}
  gem.homepage      = "https://github.com/jnraine/safety-pin"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "safety-pin"
  gem.require_paths = ["lib"]
  gem.version       = SafetyPin::VERSION

  gem.add_runtime_dependency "rest-client"
  gem.add_development_dependency "rspec", "~> 2.10.0"
end
