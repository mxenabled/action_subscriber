### Changelog

### 7.5.0 - August 6, 2026

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