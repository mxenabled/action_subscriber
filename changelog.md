### Changelog

### Unreleased

**Added:** a first party `durable` setting, so durability can be configured
rather than only passed per route. Configurable globally — including from
`config/action_subscriber.yml`, which means an operator can turn it on without a
code change — or per subscriber:

```yaml
production:
  durable: true
```

```ruby
class UserSubscriber < ::ActionSubscriber::Base
  durable true
end
```

Precedence is route option > subscriber declaration > `config.durable`, with
`:quorum` and `:stream` still forcing durability regardless. The default is
unchanged at `false`.

This is the smallest way onto RabbitMQ 4.x, which refuses the transient queues
every default route declares. `config.queue_type = :quorum` also works, but
changes the queue type as well; `config.durable` leaves it alone.

**Fixed:** `ActionSubscriber::MessageRetry` declared its retry queues without
passing `:durable`. On JRuby that was harmless, because march_hare forces quorum
and stream queues durable internally — but bunny does not, so on MRI a
`config.queue_type` of `:quorum` made every retry declaration fail with
`PRECONDITION_FAILED - invalid property 'non-durable' for queue`. Retry queues
are now declared durable whenever the configured queue type requires it, and
they follow `config.durable` as well — otherwise a deployment that set
`config.durable` to get onto RabbitMQ 4.x would still fall over the first time a
message was retried.

**Testing:** CI now runs the integration suite against the latest RabbitMQ 3.x
and 4.x on both drivers, and two new integration specs assert what the broker
actually created rather than what was put on the wire —
`spec/integration/queue_type_spec.rb` covers the queue type each route produces
(including the redeclaration conflicts that made a durable quorum queue
unusable before the `queue_type` setting existed), and
`spec/integration/broker_compatibility_spec.rb` pins the differences between the
two broker series.

That second file documents a limitation rather than fixing it: routes still
default to `:durable => false`, and RabbitMQ 4.x denies transient non-exclusive
queues, so the default route shape cannot be declared on a stock 4.x broker.
Set `config.queue_type = :quorum` (or `:durable => true`) to run on 4.x. See
"Supported RabbitMQ Versions" in the README.

### 6.0.0 - August 6, 2026

**Breaking change on JRuby.** `march_hare` defaults its `:type` option to
`classic` and so was injecting `x-queue-type: classic` on every queue it
declared, while `bunny` sent no argument at all. Both drivers are now passed
`:type` explicitly, defaulting to `nil`, so neither sends `x-queue-type` and the
broker's own `default_queue_type` applies.

MRI behavior is unchanged. On JRuby, newly declared queues change from `classic`
to whatever the broker defaults to. Set `config.queue_type = :classic` to retain
the previous JRuby behavior. Note that queue type is fixed at declaration:
redeclaring an existing queue with a conflicting type fails with
`PRECONDITION_FAILED`, so audit any vhost whose `default_queue_type` is not
classic before upgrading.

Added a first party `queue_type` setting behind that change, configurable
globally (`config.queue_type`) or per route (`:queue_type => ...`). Values are
`nil` (default), `:classic`, `:quorum` and `:stream`; `:broker_default` is
accepted as a readable alias for `nil`. `:quorum` and `:stream` force the route
to be durable. Invalid values raise where they are assigned.

### 5.4.0 - April 10, 2026
Added Ruby 3.4 / JRuby 10 support.