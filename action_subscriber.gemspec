# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'action_subscriber/version'

Gem::Specification.new do |spec|
  spec.name                  = "action_subscriber"
  spec.version               = ActionSubscriber::VERSION
  spec.authors               = ["Brian Stien","Adam Hutchison","Brandon Dewitt","Devin Christensen","Michael Ries"]
  spec.email                 = ["brianastien@gmail.com","liveh2o@gmail.com","brandonsdewitt@gmail.com","quixoten@gmail.com","michael@riesd.com"]
  spec.description           = %q{ActionSubscriber is a DSL that allows a rails app to consume messages from a RabbitMQ broker.}
  spec.summary               = %q{ActionSubscriber is a DSL that allows a rails app to consume messages from a RabbitMQ broker.}
  spec.homepage              = "https://github.com/moneydesktop/action_subscriber"
  spec.license               = "MIT"

  spec.files                 = `git ls-files`.split($/)
  spec.executables           = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files            = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths         = ["lib"]
  spec.required_ruby_version = Gem::Requirement.new(">= 2.0")

  spec.add_dependency 'activesupport', '>= 3.2'

  if ENV['PLATFORM'] == "java" || ::RUBY_PLATFORM == 'java'
    spec.platform = "java"
    spec.add_dependency 'march_hare', '>= 2.7.0'
  else
    spec.add_dependency 'bunny', '>= 1.5.0'
  end
  spec.add_dependency 'lifeguard'
  spec.add_dependency 'middleware'

  spec.add_development_dependency "activerecord", ">= 3.2"
  spec.add_development_dependency "bundler", ">= 1.6"
  spec.add_development_dependency "pry-nav"
  spec.add_development_dependency "rabbitmq_http_api_client", "~> 1.2.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake"
end
