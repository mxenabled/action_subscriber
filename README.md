[![Build Status](https://travis-ci.org/moneydesktop/action_subscriber.svg?branch=master)](https://travis-ci.org/moneydesktop/action_subscriber)

[![Code Climate](https://codeclimate.com/github/moneydesktop/action_subscriber/badges/gpa.svg)](https://codeclimate.com/github/moneydesktop/action_subscriber)

ActionSubscriber
=================
ActionSubscriber is a DSL for for easily intergrating your Rails app with a RabbitMQ messaging server.

Requirements
-----------------
I test on Ruby 2.1.1 and Jruby 1.7.x.  Ruby 1.8 is not supported.

Supported Message Types
-----------------
ActionSubscriber support JSON and plain text out of the box, but you can easily
add support for any custom message type.

Example
-----------------
A subscriber is set up by creating a class that inherits from ActionSubscriber::Base.

```ruby
class UserSubscriber < ::ActionSubscriber::Base
  publisher :user_hq

  def created
    # do something when a user is created
  end
end
```

checkout the examples dir for more detailed examples.

Usage
-----------------
ActionSubscriber is inspired by rails observers, and if you are familiar with rails
observers the ActionSubscriber DSL should make you feel right at home!

First, create a subscriber the inherits from ActionSubscriber::Base

Then, when your app starts up, you will need to load your subscriber code and then do

```ruby
ActionSubscriber.start_subscribers
while true
  sleep 1.0
end
```

or

```ruby
::ActionSubscriber.start_queues
while true
  ::ActionSubscriber.auto_pop!
  sleep 1.0
end
```

Any public methods on your subscriber will be registered as queues with rabbit with
routing keys named intelligently.

Once ActionSubscriber receives a message, it will call the associated method and the
parameter you recieve will be a decoded message.

Configuration
-----------------
ActionSubscriber needs to know how to connect to your rabbit server to start getting messages.

In an initializer, you can set the host and the port like this :

    ActionSubscriber::Configuration.configure do |config|
      config.host = "my rabbit host"
      config.port = 5672
    end

Other configuration options include :

* config.allow_low_priority_methods - subscribe to queues for methods suffixed with "_low"
* config.default_exchange - set the default exchange that your queues will use, using the default RabbitMQ exchange is not recommended
* config.hosts - an array of hostnames in your cluster
* config.times_to_pop - when using RabbitMQ's pull API, the number of messages we will grab each time we pool the broker
* config.threadpool_size - set the number of threads availiable to action_subscriber
* config.error_handler - handle error like you want to handle them!
* config.add_decoder - add a custom decoder for a custom content type

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
