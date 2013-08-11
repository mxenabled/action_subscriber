# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'action_subscriber/version'

Gem::Specification.new do |spec|
  spec.name          = "action_subscriber"
  spec.version       = ActionSubscriber::VERSION
  spec.authors       = ["Brian Stien"]
  spec.email         = ["brian.stien@moneydesktop.com"]
  spec.description   = %q{ActionSubscriber is a DSL that allows a rails app to consume messages from a RabbitMQ broker.}
  spec.summary       = %q{ActionSubscriber is a DSL that allows a rails app to consume messages from a RabbitMQ broker.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'activesupport', "~> 3.2.0"
  spec.add_dependency 'amqp'
  spec.add_dependency 'celluloid'

  spec.add_development_dependency "better_receive"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry-nav"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-pride"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "simplecov"
end
