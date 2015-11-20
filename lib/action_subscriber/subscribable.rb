module ActionSubscriber
  module Subscribable
    def allow_low_priority_methods?
      !!(::ActionSubscriber.configuration.allow_low_priority_methods)
    end

    def filter_low_priority_methods(methods)
      if allow_low_priority_methods?
        return methods
      else
        return methods - methods.grep(/_low/)
      end
    end

    def generate_queue_name(method_name)
      [
        local_application_name,
        remote_application_name,
        resource_name,
        method_name
      ].compact.join('.')
    end

    def generate_routing_key_name(method_name)
      [
        remote_application_name,
        resource_name,
        method_name
      ].compact.join('.')
    end

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

    # Build the `queue` for a given method.
    #
    # If the queue name is not set, the queue name is
    #   "local.remote.resoure.action"
    #
    # Example
    #   "bob.alice.user.created"
    #
    def queue_name_for_method(method_name)
      return queue_names[method_name] if queue_names[method_name]

      queue_name = generate_queue_name(method_name)
      queue_for(method_name, queue_name)
      return queue_name
    end

    # The name of the resource respresented by this subscriber.
    # If the class name were `UserSubscriber` the resource_name would be `user`.
    #
    def resource_name
      @_resource_name ||= self.name.underscore.gsub(/_subscriber/, '').to_s
    end

    # Build the `routing_key` for a given method.
    #
    # If the routing_key name is not set, the routing_key name is
    #   "remote.resoure.action"
    #
    # Example
    #   "amigo.user.created"
    #
    def routing_key_name_for_method(method_name)
      return routing_key_names[method_name] if routing_key_names[method_name]

      routing_key_name = generate_routing_key_name(method_name)
      routing_key_for(method_name, routing_key_name)
      return routing_key_name
    end

    def subscribable_methods
      return @_subscribable_methods if @_subscribable_methods

      methods = instance_methods
      methods -= ::Object.instance_methods

      self.included_modules.each do |mod|
        methods -= mod.instance_methods
      end

      @_subscribable_methods = filter_low_priority_methods(methods)
      @_subscribable_methods.sort!

      return @_subscribable_methods
    end
  end
end
