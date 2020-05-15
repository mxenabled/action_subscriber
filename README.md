[![Build Status](https://travis-ci.org/mxenabled/action_subscriber.svg?branch=master)](https://travis-ci.org/mxenabled/action_subscriber)
[![Code Climate](https://codeclimate.com/github/mxenabled/action_subscriber/badges/gpa.svg)](https://codeclimate.com/github/mxenabled/action_subscriber)
[![Dependency Status](https://gemnasium.com/mxenabled/action_subscriber.svg)](https://gemnasium.com/mxenabled/action_subscriber)
[![Join the chat at https://gitter.im/mxenabled/action_subscriber](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/mxenabled/action_subscriber?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

ActionSubscriber
=================
ActionSubscriber is a DSL for for easily intergrating your Rails app with a RabbitMQ messaging server.

Requirements
-----------------
I test on Ruby 2.2.1 and Jruby 9.x.  MRI 1.9 and jRuby 1.7 are still supported.

If you want to use MRI 1.9 you will need to lock down the `amq-protocol` and `bunny` gems to `< 2.0` since they both require ruby 2.0+.

Migrating from ActionSubscriber 3.X or earlier
----------------------------------------------

If you were using the `--mode=pop` from the 2.X or 3.X version of ActionSubscriber you can get the same sort of behavior by drawing your routes like this:

```ruby
::ActionSubscriber.draw_routes do
  # instead of creating custom threadpools you set the threadpool size of your connection here in the routes
  # you can set the threadpool size for the default connection via the `::ActionSubscriber.configuration.threadpool_size = 16`
  route UserSubscriber, :created,
    :prefetch => 1,
    :concurrency => 16,
    :acknowledgements => true

  # in user_subscriber.rb make sure to set `at_most_once!` like this
  #
  # class UserSubscriber < ::ActionSubscriber::Base
  #   at_most_once!
  # end

  # If you were previously using custom threadpools for different routes you can mimic that behavior by opening multiple connections
  connection(:slow_work, :threadpool_size => 32) do
    route UserSubscriber, :created,
      :prefetch => 1,
      :concurrency => 32,
      :acknowledgements => true
  end
end
```

That will give you a similar behavior to the old `--mode=pop` where messages polled from the server, but with reduced latency.

Supported Message Types
-----------------
ActionSubscriber support JSON and plain text out of the box, but you can easily
add support for any custom message type.

Example
-----------------
A subscriber is set up by creating a class that inherits from ActionSubscriber::Base.

```ruby
class UserSubscriber < ::ActionSubscriber::Base
  def created
    # do something when a user is created
  end
end
```

checkout the examples dir for more detailed examples.

Usage
-----------------

In your application setup you will draw your subscription routes. In a rails app this is usually done in `config/initializers/action_subscriber.rb`.

```ruby
::ActionSubscriber.draw_routes do
  # you can define routes one-by-one for fine-grained controled
  route UserSubscriber, :created

  # or you can setup default routes for all the public methods in a subscriber
  default_routes_for UserSubscriber
end
```

Now you can start your subscriber process with:


```
$ bundle exec action_subscriber start
```

This will connect your subscribers to the rabbitmq broker and allow it to push messages down to your subscribers.

### Around Filters
"around" filters are responsible for running their associated actions by yielding, similar to how Rack middlewares work (and Rails around filters work)

```ruby
class UserSubscriber < ::ActionSubscriber::Base
  around_filter :log_things

  def created
    # do something when a user is created
  end

  private

  def log_things
    puts "before I do some stuff"
    yield
    puts "I did some stuff"
  end
end
```

> Warning: an around filter will only be added once to the chain, duplicate around filters are not supported

Configuration
-----------------
ActionSubscriber needs to know how to connect to your rabbit server to start getting messages.

In an initializer, you can set the host and the port like this :

    ActionSubscriber.configure do |config|
      config.hosts = ["rabbit1", "rabbit2", "rabbit3"]
      config.port = 5672
    end

Other configuration options include :

* config.add_decoder - add a custom decoder for a custom content type
* config.allow_low_priority_methods - Subscribe to `*_low` queues in addition to normal queues.
* config.connection_reaping_interval - Connection reaping interval when using a project ActiveRecord
* config.connection_reaping_timeout_interval - Connection reaping timeout interval when using a project ActiveRecord
* config.default_exchange - set the default exchange that your queues will use, using the default RabbitMQ exchange is not recommended
* config.error_handler - handle error like you want to handle them!
* config.heartbeat - number of seconds between hearbeats (default 5) [see bunny documentation for more details](http://rubybunny.info/articles/connecting.html)
* config.hosts - an array of hostnames in your cluster (ie `["rabbit1.myapp.com", "rabbit2.myapp.com"]`)
* config.network_recovery_interval - reconnection interval for TCP connection failures (default 1)
* config.password - RabbitMQ password (default "guest")
* config.prefetch - number of messages to hold in the local queue in subscriber mode
* config.resubscribe_on_consumer_cancellation - resubscribe when the consumer is cancelled (queue deleted or cluster fails, default true)
* config.seconds_to_wait_for_graceful_shutdown - time to wait before force stopping server after shutdown signal
* config.threadpool_size - set the number of threads available to action_subscriber
* config.timeout - how many seconds to allow rabbit to respond before timing out
* config.tls - true/false whether to use TLS when connecting to the server
* config.tls_ca_certificats - a list of ca certificates to use for verifying the servers TLS certificate
* config.tls_cert - a client certificate to use during the TLS handshake
* config.tls_key - a key to use during the TLS handshake
* config.username - RabbitMQ username (default "guest")
* config.verify_peer - whether to attempt to validate the server's TLS certificate
* config.virtual_host - RabbitMQ virtual host (default "/")

> Note: TLS is not handled identically in `bunny` and `march_hare`. The configuration options we provide are passed through as provided. For details on expected behavior please check the `bunny` or `march_hare` documentation based on whether you are running in MRI or jRuby.

Message Acknowledgment
----------------------
### no_acknolwedgement!

This mode is the default. Rabbit is told to not expect any message acknowledgements so messages will be lost if an error occurs.
This also allows the broker to send messages as quickly as it wants down to your subscriber.

> Warning: If messages arrive very quickly this could cause your process to crash as your memory fills up with unprocessed message.
> We highly recommend you use `at_least_once!` mode to provide a throttle so the broker does not overwhelm your process with messages.

### manual_acknowledgement!

This mode leaves it up to the subscriber to handle acknowledging or rejecting messages. In your subscriber you can just call <code>acknowledge</code>, <code>reject</code>, or <code>nack</code>.

### at_most_once!

Rabbit is told to expect message acknowledgements, but sending the acknowledgement is left up to ActionSubscriber. We send the acknowledgement right before calling your subscriber.

### at_least_once!

Rabbit is told to expect message acknowledgements, but sending the acknowledgement is left up to ActionSubscriber.
We send the acknowledgement right after calling your subscriber.
If an error is raised your message will be retried on a sent back to rabbitmq and retried on an exponential backoff schedule.

### safe_nack
If you turn on acknowledgements and a message is not acknowledged by your code manually or using one of the filters above the `ErrorHandler` middleware
which wraps the entire block with call <code>nack</code> this is a last resort so the connection does not get backed up in cases of unexpected or
unhandled errors.

### redeliver

A message can be sent to "redeliver" with `::ActionSubscriber::MessageRetry.redeliver_message_with_backoff` or the DSL method `redeliver` and optionally
takes a "backoff schedule" which is a hash of backoff milliseconds for each redeliver, the default:

```ruby
  SCHEDULE = {
    2  =>        100,
    3  =>        500,
    4  =>      2_500,
    5  =>     12_500,
    6  =>     62_500,
    7  =>    312_500,
    8  =>  1_562_500,
    9  =>  7_812_500,
    10 => 39_062_500,
  }
```

when the schedule "returns" `nil` the message will not be retried

> Warning: If you use `redeliver` you need to handle reject/acknowledge according how errors are handled; if an error is caught and the
> ack/reject is already done then you may duplicate the message in `at_least_once!` mode

Testing
-----------------
ActionSubscriber includes support for easy unit testing with RSpec.

In your spec_helper.rb:

```
require 'action_subscriber/rspec'

RSpec.configure do |config|
  config.include ::ActionSubscriber::RSpec
end
```

In your_subscriber_spec.rb :
``` subject { mock_subscriber }```

Your test subject will be an instance of your subscriber class, and you can
easily test your public methods without dependence on data from Rabbit.  You can
optionally pass data for your mock subscriber to consume if you wish.

``` subject { mock_subscriber(:header => "test_header", :payload => "payload") } ```

Development
===========

If you want to work on `action_subscriber` you will need to have a rabbitmq instance running locally on port 5672 with a management plugin enabled on port 15672. Usually the easiest way to accomplish this is to use docker and run the command:

```
$ docker run --net=host --rm=true --hostname diagon --name rabbit rabbitmq:3.6.6-management
```

Now that rabbitmq is running you can clone this project and run:

```
$ cd action_subscriber
$ bundle install
$ bundle exec rspec
```
