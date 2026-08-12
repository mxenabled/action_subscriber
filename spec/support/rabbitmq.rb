require "socket"
require "rabbitmq/http/client"

# Helpers for running the suite against a real RabbitMQ broker.
#
# The integration specs talk to a live broker (the same approach used in CI, where a
# `rabbitmq` service container is started alongside the test job). Locally you can point
# at any running broker via the standard host+port; by default we assume localhost:5672
# with the management plugin on 15672.
#
# CI runs the suite against more than one broker series (see .circleci/config.yml). The
# two series do not accept the same queue declarations, so specs that care branch on the
# helpers here rather than on a hardcoded version:
#
#   * RabbitMQ 3.x has `transient_nonexcl_queues` in the `permitted_by_default`
#     deprecation phase, so action_subscriber's default (non-durable) route declares
#     fine.
#   * RabbitMQ 4.x moved it to `denied_by_default`. A non-durable, non-exclusive queue
#     declaration is refused with a *connection*-level 541 INTERNAL_ERROR, which tears
#     down the whole connection rather than just the channel. To run the default route
#     shape against 4.x a broker has to opt back in:
#
#       # rabbitmq.conf
#       deprecated_features.permit.transient_nonexcl_queues = true
#
#     CI instead runs the 4.x job with ACTION_SUBSCRIBER_QUEUE_TYPE=quorum, since quorum
#     queues are always durable and so sidestep the deprecated feature entirely.
module RabbitMQTestHelper
  module_function

  # Every environment variable the suite honors goes through here. Blank is treated as
  # unset: a CircleCI job parameter that defaults to "" still reaches the environment as
  # an empty string. Pass a block to coerce a value that is actually present.
  #
  # Reads are recorded so the suite can print back exactly what a run was configured
  # with. Deriving that from what was actually consumed, rather than from a hand-kept
  # list, is the only way it stays correct as knobs are added.
  def env(name, default = nil)
    value = ENV[name].to_s.strip
    return default if value.empty?
    observed_env[name] = value
    block_given? ? yield(value) : value
  end

  # Raw strings, so they can be pasted back into a shell. Only variables that were
  # actually set appear -- defaults are not worth restating.
  def observed_env
    @observed_env ||= {}
  end

  # The broker version if some earlier call already fetched it, otherwise nil. Callers
  # that only want it for a diagnostic must not trigger the fetch: the management client
  # has generous timeouts, and a unit-only run has no broker to ask.
  def known_broker_version
    @broker_version
  end

  def host
    env("RABBITMQ_HOST", "127.0.0.1")
  end

  def port
    env("RABBITMQ_PORT", 5672) { |value| Integer(value) }
  end

  def management_port
    env("RABBITMQ_MANAGEMENT_PORT", 15672) { |value| Integer(value) }
  end

  def username
    env("RABBITMQ_USERNAME", "guest")
  end

  def password
    env("RABBITMQ_PASSWORD", "guest")
  end

  def vhost
    env("RABBITMQ_VHOST", "/")
  end

  # Timeouts are set explicitly: the client passes its options straight to Faraday, which
  # sets none of its own, so the Net::HTTP defaults (60s connect, 60s read) apply. A host
  # that drops packets rather than refusing -- a killed CI service container, say -- would
  # otherwise wedge the suite for two minutes with no output.
  def http_client
    @http_client ||= ::RabbitMQ::HTTP::Client.new(
      "http://#{host}:#{management_port}",
      :username => username,
      :password => password,
      :request => { :open_timeout => 5, :timeout => 5 }
    )
  end

  # e.g. "3.13.7" or "4.3.4"
  def broker_version
    @broker_version ||= http_client.overview.rabbitmq_version.to_s
  end

  def broker_major
    @broker_major ||= Integer(broker_version.split(".").first)
  end

  # The vhost's default_queue_type, which is what the broker resolves an absent
  # x-queue-type to. 3.x reports it as the string "undefined" when unset and 4.x reports
  # it explicitly; unset behaves as "classic" either way.
  def default_queue_type
    @default_queue_type ||= begin
      record = http_client.vhost_info(vhost)
      type = record.respond_to?(:default_queue_type) ? record.default_queue_type.to_s : ""
      type.empty? || type == "undefined" ? "classic" : type
    end
  end

  # Probed rather than inferred from the version, because a 4.x broker can permit the
  # feature back on and a 3.x broker can deny it. Memoized -- the probe costs a
  # connection, and on 4.x it costs a *failed* one.
  def transient_nonexcl_queues_permitted?
    return @transient_nonexcl_queues_permitted if defined?(@transient_nonexcl_queues_permitted)

    name = "action_subscriber.spec.transient_probe"
    @transient_nonexcl_queues_permitted =
      begin
        declare_queue!(name, :durable => false, :type => "classic")
        delete_queue!(name)
        true
      rescue ::StandardError
        false
      end
  end

  ##
  # Out-of-band queue management
  #
  # These deliberately use their own connection rather than
  # ActionSubscriber::RabbitConnection, so that a declaration the broker refuses cannot
  # poison the connection the subscribers are using. On 4.x a denied transient
  # declaration closes the whole connection, not just the channel.
  #

  # One short-lived connection per call. Reusing a memoized one is tempting -- the suite
  # makes ~40 of them per run -- but it was tried and reverted: several specs here
  # deliberately provoke a connection-level refusal (4.x answers a denied transient queue
  # with a 541), and bunny does not reliably recover a connection in that state. Reuse
  # produced order-dependent failures and, twice, a suite that hung past 700s. The
  # handshakes are cheaper than the flakiness.
  def with_raw_channel
    connection = build_raw_connection
    yield(connection.create_channel)
  ensure
    begin
      connection.close if connection
    rescue ::StandardError
      nil
    end
  end

  def declare_queue!(name, options = {})
    with_raw_channel { |channel| declare(channel, name, options) }
  end

  # Declares the queue a route describes, using the same option mapping the drivers'
  # setup_queue uses. Keeping that mapping in one place stops specs from asserting
  # against a stale copy of it. Out-of-band on purpose -- unlike RouteSet#setup_queue
  # this cannot take the subscribers' connection down with it.
  #
  # `name` is overridable because a spec often wants a route's *settings* without
  # touching the queue its own subscription already declared.
  def declare_route_queue!(route, name = route.queue)
    declare_queue!(name, :durable => route.durable, :type => route.driver_queue_type)
  end

  def delete_queue!(name)
    with_raw_channel { |channel| channel.queue_delete(name) }
  rescue ::StandardError
    nil
  end

  # Deletes every queue in the vhost. The suite needs this because a queue's type and
  # durability are fixed at declaration: a queue left behind by a previous run under a
  # different queue type fails every later redeclaration with PRECONDITION_FAILED. Not
  # all of the suite's queues are named after APP_NAME (some specs name their own), so
  # there is nothing narrower to key on -- and spec/integration/consumer_cancellation
  # already clears the whole vhost mid-suite. Point the suite at a broker you own.
  def delete_all_queues!
    http_client.list_queues(vhost).each do |queue|
      http_client.delete_queue(queue.vhost, queue.name)
    end
  rescue ::StandardError
    nil
  end

  # The broker's view of a queue -- notably `type` and `durable`, which is the only way
  # to tell what a declaration actually produced when x-queue-type was left off the wire.
  def queue_info(name)
    http_client.queue_info(vhost, name)
  end

  def queue_type_of(name)
    queue_info(name).type.to_s
  end

  def queue_durable?(name)
    queue_info(name).durable
  end

  # Block until the broker is reachable, or raise after `timeout` seconds. Keeps the
  # suite from failing with confusing connection errors when the broker is still booting
  # (common in CI service containers).
  #
  # Waits on the management API as well as AMQP: the suite reads queue types back over
  # HTTP, and the management plugin finishes starting after the AMQP listener does. No
  # separate wait on the management *port* -- a closed one surfaces as ECONNREFUSED from
  # the overview call, which retries against the same deadline.
  def wait_for_rabbitmq!(timeout: env("RABBITMQ_WAIT_TIMEOUT", 60) { |value| Integer(value) })
    deadline = ::Time.now + timeout

    wait_until!(deadline, "AMQP port #{host}:#{port} to accept a connection") do
      ::Socket.tcp(host, port, connect_timeout: 1, &:close)
      true
    end

    wait_until!(deadline, "management API at #{host}:#{management_port} to answer") do
      # overview is only served once the management plugin is fully up.
      @broker_version = nil
      !broker_version.empty?
    end
  end

  # Retry the block until it returns truthy or the deadline passes, then raise naming
  # what we were waiting for and why the last attempt failed.
  def wait_until!(deadline, description)
    last_error = nil
    loop do
      begin
        return true if yield
      rescue ::StandardError => e
        last_error = e
      end

      if ::Time.now >= deadline
        raise "Timed out waiting for #{description} " \
              "(last error: #{last_error.class}: #{last_error.message}). " \
              "Start a broker (see spec/support/rabbitmq.rb) before running the integration suite."
      end
      sleep 0.5
    end
  end

  # Several specs here declare queues the broker is expected to refuse, and a refusal at
  # the connection level (4.x answers a denied transient queue with a 541) makes the
  # driver log the resulting socket teardown with a full Java backtrace. Expected noise,
  # so keep it out of the CI log.
  def quiet_logger
    @quiet_logger ||= ::Logger.new(::File::NULL)
  end

  def build_raw_connection
    if ::RUBY_PLATFORM == "java"
      ::MarchHare.connect(:host => host, :port => port, :username => username,
                          :password => password, :vhost => vhost,
                          :logger => quiet_logger)
    else
      connection = ::Bunny.new(:host => host, :port => port, :username => username,
                               :password => password, :vhost => vhost,
                               :log_level => :fatal, :automatically_recover => false,
                               # Bunny does not decode the 541 a 4.x broker sends for a
                               # denied transient queue, it just waits out this timeout.
                               # Three specs deliberately trigger that, so keep it tight.
                               :continuation_timeout => 2_000)
      connection.start
      connection
    end
  end

  # bunny and march_hare disagree about an omitted :type -- march_hare fills in
  # "classic", bunny sends nothing -- so always pass it explicitly here, the same way
  # ActionSubscriber::QueueType makes the drivers agree.
  def declare(channel, name, options)
    channel.queue(name, { :type => nil }.merge(options))
  end
end
