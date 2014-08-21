# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hustle/version'

Gem::Specification.new do |gem|
  gem.name          = "hustle"
  gem.version       = Hustle::VERSION
  gem.authors       = ["Nathan Hopkins"]
  gem.email         = ["natehop@gmail.com"]
  gem.description   = "Run Ruby blocks inside their own process."
  gem.summary       = "Run Ruby blocks inside their own process."
  gem.homepage      = "https://github.com/hopsoft/hustle"
  gem.license       = "MIT"

  gem.files         = Dir["lib/**/*.rb", "bin/*", "[A-Z].*"]
  gem.test_files    = Dir["test/**/*.rb"]
  gem.require_paths = ["lib"]

  gem.add_dependency "os", "~> 0.9.6"
  gem.add_dependency "method_source", "~> 0.8.2"

  gem.add_development_dependency "bundler", "~> 1.5"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "pry"
  gem.add_development_dependency "micro_test", "~> 0.4.4"
end
