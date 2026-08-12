module ActionSubscriber
  class Router
    def self.draw_routes(&block)
      router = self.new
      router.instance_eval(&block)
      router.routes
    end

    # :durable is deliberately absent -- baking it in here would make an unspecified
    # route indistinguishable from one that explicitly asked for false, and Route needs
    # to tell them apart to fall back to config.durable. Same reason :prefetch is absent.
    #
    # The two keys that remain predate that rule and do not follow it: :exchange shadows
    # config.default_exchange, and :acknowledgements shadows the subscriber's
    # at_least_once! / manual_acknowledgement! declaration, for `route` but not for
    # `default_routes_for`. Moving either into Route is a behavior change, not a cleanup.
    DEFAULT_SETTINGS = {
      :acknowledgements => false,
      :exchange => "events",
    }.freeze

    def initialize
      @current_threadpool_name = :default
    end

    def connection(name, settings, &block)
      ::ActionSubscriber.print_deprecation_warning("setting up a threadpool for #{name} instead of a new connection")
      threadpool(name, settings, &block)
    end

    def threadpool(name, settings)
      ::ActionSubscriber::ThreadPools.setup_threadpool(name, settings)
      @current_threadpool_name = name
      yield
      @current_threadpool_name = :default
    end

    def default_routing_key_for(route_settings)
      [
        route_settings[:publisher],
        resource_name(route_settings),
        route_settings[:action].to_s,
      ].compact.join(".")
    end

    def default_queue_for(route_settings)
      [
        local_application_name,
        route_settings[:publisher],
        resource_name(route_settings),
        route_settings[:action].to_s,
      ].compact.join(".")
    end

    def default_routes_for(subscriber, options = {})
      options = options.merge({:threadpool_name => @current_threadpool_name})
      subscriber.routes(options).each do |route|
        routes << route
      end
    end

    def local_application_name
      @_local_application_name ||= begin
        local_application_name = case
                                 when ENV['APP_NAME'] then
                                   ENV['APP_NAME'].to_s.dup
                                 when defined?(::Rails) then
                                   if ::Rails.application.class.respond_to?(:module_parent_name)
                                     ::Rails.application.class.module_parent_name.dup
                                   else
                                     ::Rails.application.class.parent_name.dup
                                   end
                                 else
                                   raise "Define an application name (ENV['APP_NAME'])"
                                 end
        local_application_name.downcase
      end
    end

    def resource_name(route_settings)
      route_settings[:subscriber].name.underscore.gsub(/_subscriber/, "").to_s
    end

    def route(subscriber, action, options = {})
      route_settings = DEFAULT_SETTINGS.merge(:threadpool_name => @current_threadpool_name).merge(options).merge(:subscriber => subscriber, :action => action)
      route_settings[:routing_key] ||= default_routing_key_for(route_settings)
      route_settings[:queue] ||= default_queue_for(route_settings)
      routes << Route.new(route_settings)
    end

    def routes
      @routes ||= []
    end
  end
end
