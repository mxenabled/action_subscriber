# Prints how to reproduce a failed run.
#
# The seed on its own is not enough. Ordering depends on it, but behaviour depends on
# which broker the run talked to and which settings it ran under -- and CI varies all
# three across the matrix. Worse, EXPECTED_RABBITMQ_MAJOR decides whether an example is
# defined at all, so omitting it changes the example count and the same seed shuffles a
# different list.
#
# Registered as a :close listener rather than an after(:suite) hook. Suite hooks run
# inside Reporter#report, so their output lands above the failure dump and above RSpec's
# own seed line -- i.e. scrolled off the bottom of a CI log, which is where anyone
# reading a failed job starts. :close fires last.
class ReproductionReporter
  def self.register!(configuration)
    configuration.reporter.register_listener(new(configuration.output_stream), :close)
  end

  def initialize(output)
    @output = output
  end

  def close(_notification)
    failures = ::RSpec.configuration.reporter.failed_examples
    return if failures.empty?

    @output.puts(message)
  end

  private

  def message
    <<~REPRO

      Reproduce this run#{broker_description} with:

        #{command}
    REPRO
  end

  def command
    settings = RabbitMQTestHelper.observed_env.dup
    # Bundler reads BUNDLE_GEMFILE itself, so it never passes through the helper. It
    # names the Rails half of the CI matrix, so it belongs in the command. Relative, so
    # the line pastes cleanly.
    gemfile = ENV["BUNDLE_GEMFILE"].to_s.strip
    settings["BUNDLE_GEMFILE"] = gemfile.sub("#{::Dir.pwd}/", "") unless gemfile.empty?

    assignments = settings.sort.map { |name, value| "#{name}=#{value}" }
    (assignments + ["bundle exec rspec --seed #{::RSpec.configuration.seed}"]).join(" \\\n  ")
  end

  def broker_description
    version = RabbitMQTestHelper.known_broker_version
    version ? " against RabbitMQ #{version}" : ""
  end
end
