# Taken and adapted from https://github.com/ruby-amqp/amq-protocol/blob/master/lib/amq/uri.rb
require "cgi"
require "uri"

module ActionSubscriber
  class URI
    AMQP_PORTS = {"amqp" => 5672, "amqps" => 5671}.freeze

    def self.parse_amqp_url(connection_string)
      uri = ::URI.parse(connection_string)
      raise ArgumentError.new("Connection URI must use amqp or amqps schema (example: amqp://bus.megacorp.internal:5766), learn more at http://bit.ly/ks8MXK") unless %w{amqp amqps}.include?(uri.scheme)

      opts = {}

      opts[:username]   = ::CGI::unescape(uri.user) if uri.user
      opts[:password]   = ::CGI::unescape(uri.password) if uri.password
      opts[:host]   = uri.host if uri.host
      opts[:port]   = uri.port || AMQP_PORTS[uri.scheme]

      if uri.path =~ %r{^/(.*)}
        raise ArgumentError.new("#{uri} has multiple-segment path; please percent-encode any slashes in the vhost name (e.g. /production => %2Fproduction). Learn more at http://bit.ly/amqp-gem-and-connection-uris") if $1.index('/')
        opts[:virtual_host] = ::CGI::unescape($1)
      end

      opts
    end
  end
end
