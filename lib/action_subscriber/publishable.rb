module ActionSubscriber
  module Publishable

    def self.included(base)
      base.class_eval do
        after_create  :publish_created_event
        after_destroy :publish_deleted_event
        after_save    :publish_event

        def generate_routing_key_name(method_name)
          [
            local_application_name,
            resource_name,
            method_name
          ].compact.join('.')
        end

        def exchange_name(name = nil)
          @exchange_name ||= name

          if @_exchange_name.blank? 
            return ::ActionSubscriber.config.default_exchange
          else
            return @exchange_name
          end
        end

        alias_method :exchange, :exchange_name

        def local_application_name(reload = false)
          if reload || @_local_application_name.nil?
            @_local_application_name = case
                                       when ENV['APP_NAME'] then
                                         ENV['APP_NAME'].to_s.dup
                                       when defined?(::Rails) then
                                         ::Rails.application.class.parent_name.dup
                                       else
                                         raise "Define an application name (ENV['APP_NAME'])"
                                       end

            @_local_application_name.downcase!
          end

          @_local_application_name
        end

        def publish_created_event
          publish(:created)
          true
        end

        def publish_destroyed_event
          publish(:deleted)
          true
        end

        def publish_event
          operation = :created
          operation = :updated unless self.new_record?
          operation = :deleted if     self.destroyed?

          publish(operation)

          true
        end

        def publish(operation)
          channel = ActionSubscriber::RabbitConnection.connection.create_channel
          exchange = channel.topic(exchange_name)
          exchange.publish(self.to_json, :routing_key => generate_routing_key_name(operation))
        end

        def resource_name
          self.class.name.underscore
        end
      end
    end
  end
end
