ActionSubscriber
=================
ActionSubscriber is a DSL for for easily intergrating your Rails app with a RabbitMQ messaging server.

Requirements
-----------------
I test on Ruby 1.9.3 and Jruby 1.7.x.  Ruby 1.8 is not supported.

Supported Message Types
-----------------
ActionSubscriber support JSON and plain text out of the box, but you can easily
add support for any custom message type.

Installation
-----------------

    gem install action_subscriber

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
* config.times_to_pop - when using RabbitMQ's pull API, the number of messages we will grab each time we pool the broker
* config.threadpool_size - set the number of threads availiable to action_subscriber
* config.error_handler - handle error like you want to handle them!
* config.add_decoder - add a custom decoder for a custom content type

Usage
-----------------
ActionSubscriber is inspired by rails observers, and if you are familiar with rails
observers the ActionSubscriber DSL should make you feel right at home!

First, create a subscriber the inherits from ActionSubscriber::Base

Then, when your app starts us, you will need to load your subscriber code and then do

    EventMachine.run do
      ActionSubscriber.start_subscribers
    end

Any public methods on your subscriber will be registered as queues with rabbit with
routing keys named intelligently.

Once ActionSubscriber receives a message, it will call the associated method and the 
parameter you recieve will be a decoded message.

Examples
-----------------
Check out action_subscriber/examples.
