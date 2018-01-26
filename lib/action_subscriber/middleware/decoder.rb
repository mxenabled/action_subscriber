module ActionSubscriber
  module Middleware
    class Decoder
      attr_reader :env

      def initialize(app)
        @app = app
      end

      def call(env)
        @env = env

        env.payload = decoder? ? decoder.call(encoded_payload) : encoded_payload.dup

        @app.call(env)
      end

      private

      def decoder
        ::ActionSubscriber.config.decoder[env.content_type]
      end

      def decoder?
        decoder.present?
      end

      def encoded_payload
        env.encoded_payload
      end
    end
  end
end
