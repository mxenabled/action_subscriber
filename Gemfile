source 'https://rubygems.org'

# Specify your gem's dependencies in action_subscriber.gemspec
gemspec

if RUBY_ENGINE == "ruby" && RUBY_VERSION.split(".").first.to_i < 2
  # MRI 1.9 requires older versions of bunny + amq-protocol
  gem 'amq-protocol', '< 2.0.0'
  gem 'bunny', '< 2.0.0'
end
