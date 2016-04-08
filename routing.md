# Routing In ActionSubscriber

ActionSubscriber used to automatically discover all your subscribers and infer all their routes based on a default set of rules<sup>[1](#footnotes)</sup>. As of ActionSubscriber `1.5.0` this behavior is deprecated in favor of having the application draw its routes explicitly.

## The Simple Upgrade Path

The simplest way to draw your routes is to create a `config/initializers/action_subscriber.rb` file and ask the router to setup default routes like this:

```ruby
::ActionSubscriber.draw_routes do
  default_routes_for ::UserSubscriber
  default_routes_for ::NotificationSubscriber
end
```

This is the easiest migration path for existing users to follow, but it doesn't allow for things like mixing which exchange you are subscribing to between different actions.

## Custom Routes

You can also specify custom routes for your subscribers when you want more flexibility.

```ruby
::ActionSubscriber.draw_routes do
  default_routes_for ::UserSubscriber

  route ::NotificationSubscriber, :created, :publisher => :newman, :exchange => :events
  route ::NotificationSubscriber, :send, :publisher => :newman, :exchange => :action
end
```

## Options For Routes

The `route` method supports the following options:

* `acknowledgements` this toggles whether this route is expected to provide an acknowledgment (default `false`)
  * This is the equivalent of calling `at_most_once!`, `at_least_once!` or `manual_acknowledgement!` in your subscriber class
* `durable` specifies whether the queue for this route should be a durable (default `false`)
* `exchange` specify which exchange you expect messages to be published to (default `"events"`)
  * This is the equivalent of calling `exchange :actions` in your subscriber
* `publisher` this will prefix your queue and routing key with the publishers name
  * This is the equivalent of puting `publisher :foo` in your subscriber
* `queue` specifies which queue you will subscribe to rather than letting ActionSubscriber infer it from the name of the subscriber and action
* `routing_key` specifies the routing key that will be bound to your queue

<h3 id="footnotes">Footnotes</h3>

* __1__ the old behavior of discovering and inferring routes for subscribers will be supported until the 2.0 version of ActionSubscriber. When no routes are drawn before calling `setup_queues!` we will print a deprecation warning and infer the routes for you.
