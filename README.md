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
$ bundle exec action_subscriber start --mode=subscribe
```

This will start your subscribers in a mode where they connect to rabbitmq and let the broker push messages down to them.

You can also start in `--mode=pop` where your process will poll the broker for messages.

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
* config.default_exchange - set the default exchange that your queues will use, using the default RabbitMQ exchange is not recommended
* config.error_handler - handle error like you want to handle them!
* config.heartbeat - number of seconds between hearbeats (default 5) [see bunny documentation for more details](http://rubybunny.info/articles/connecting.html)
* config.hosts - an array of hostnames in your cluster (ie `["rabbit1.myapp.com", "rabbit2.myapp.com"]`)
* config.pop_interval - how long to wait between polling for messages in `--mode=pop`. It should be a number of milliseconds
* config.threadpool_size - set the number of threads availiable to action_subscriber
* config.timeout - how many seconds to allow rabbit to respond before timing out
* config.times_to_pop - when using RabbitMQ's pull API, the number of messages we will grab each time we pool the broker

Message Acknowledgment
----------------------
### no_acknolwedgement!

This mode is the default. Rabbit is told to not expect any message acknowledgements so messages will be lost if an error occurs.

### manual_acknowledgement!

This mode leaves it up to the subscriber to handle acknowledging or rejecting messages. In your subscriber you can just call <code>acknowledge</code> or <code>reject</code>.

### at_most_once!

Rabbit is told to expect message acknowledgements, but sending the acknowledgement is left up to ActionSubscriber. We send the acknowledgement right before calling your subscriber.

### at_least_once!

Rabbit is told to expect message acknowledgements, but sending the acknowledgement is left up to ActionSubscriber. We send the acknowledgement right after calling your subscriber. If an error is raised by your subscriber we reject the message instead of acknowledging it. Rejected messages go back to rabbit and will be re-delivered.

Testing
-----------------
ActionSubscriber includes support for easy unit testing with RSpec.

In your spec_helper.rb:

```
require 'action_subscriber/rspec'

RSpec.configure do |config|
  config.include ::ActionSubscriber::Rspec
end
```

In your_subscriber_spec.rb :
``` subject { mock_subscriber }```

Your test subject will be an instance of your subscriber class, and you can
easily test your public methods without dependence on data from Rabbit.  You can
optionally pass data for your mock subscriber to consume if you wish.

``` subject { mock_subscriber(:header => "test_header", :payload => "payload") } ```
