module ActionSubscriber
  class Router
    def self.draw_routes(&block)
      router = self.new
      router.instance_eval(&block)
      router.routes
    end

    # def self.stacks
    #   @_stacks ||= {}
    # end


    DEFAULT_SETTINGS = {
      :acknowledgements => false,
      :durable => false,
      :exchange => "events",
    }.freeze

    def initialize
      @stacks ||= {}
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

    def default_routes_for(subscriber)
      subscriber.routes.each do |route|
        routes << route
      end
    end

    def resource_name(route_settings)
      route_settings[:subscriber].name.underscore.gsub(/_subscriber/, "").to_s
    end

    def stack(name, &block)
      @stacks[name] ||= ::ActionSubscriber.config.middleware.forked.instance_eval(&block)
    end

    def route(subscriber, action, options = {}, &block)
      route_settings = DEFAULT_SETTINGS.merge(options).merge(:subscriber => subscriber, :action => action)
      route_settings[:routing_key] ||= default_routing_key_for(route_settings)
      route_settings[:queue] ||= default_queue_for(route_settings)
      route_settings[:middleware] = @stacks[options[:stack]] if options.key?(:stack)
      _route = Route.new(route_settings)
      _route.instance_eval(&block) if block_given?
      routes << _route
    end

    def routes
      @routes ||= []
    end

    def local_application_name
      @_local_application_name ||= begin
        local_application_name = case
                                 when ENV['APP_NAME'] then
                                   ENV['APP_NAME'].to_s.dup
                                 when defined?(::Rails) then
                                   ::Rails.application.class.parent_name.dup
                                 else
                                   raise "Define an application name (ENV['APP_NAME'])"
                                 end
        local_application_name.downcase
      end
    end
  end
end
