require "socket"

# Helpers for running the suite against a real RabbitMQ broker.
#
# The integration specs talk to a live broker (the same approach used in CI, where a
# `rabbitmq` service container is started alongside the test job). Locally you can point
# at any running broker via RABBITMQ_URL / the standard host+port; by default we assume
# localhost:5672.
#
# NOTE: action_subscriber defaults to non-durable ("transient") queues. RabbitMQ 4.x
# denies transient non-exclusive queues by default, so a 4.x broker used for the suite
# must permit the deprecated feature:
#
#   # rabbitmq.conf
#   deprecated_features.permit.transient_nonexcl_queues = true
#
# The rabbitmq:3.12 image used in CI still allows them out of the box. See the phantom
# queue triage doc for why the production recommendation is to move to durable topology.
module RabbitMQTestHelper
  module_function

  def host
    ENV.fetch("RABBITMQ_HOST", "localhost")
  end

  def port
    Integer(ENV.fetch("RABBITMQ_PORT", "5672"))
  end

  # Block until the broker's AMQP port accepts a TCP connection, or raise after `timeout`
  # seconds. Keeps the suite from failing with confusing connection errors when the broker
  # is still booting (common in CI service containers).
  def wait_for_rabbitmq!(timeout: Integer(ENV.fetch("RABBITMQ_WAIT_TIMEOUT", "30")))
    deadline = ::Time.now + timeout
    last_error = nil
    loop do
      begin
        ::Socket.tcp(host, port, connect_timeout: 1) { |sock| sock.close }
        return true
      rescue ::StandardError => e
        last_error = e
      end

      if ::Time.now >= deadline
        raise "RabbitMQ was not reachable at #{host}:#{port} within #{timeout}s " \
              "(last error: #{last_error.class}: #{last_error.message}). " \
              "Start a broker (see spec/support/rabbitmq.rb) before running the integration suite."
      end
      sleep 0.5
    end
  end
end
