module ActionSubscriber
  module Middleware
    module Rails
      class Reloader
        def initialize(app)
          @app = app
        end

        def call(env)
          ::Rails.application.reloader.wrap do
            @app.call(env)
          end
        end
      end
    end
  end
end
