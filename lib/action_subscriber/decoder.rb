module ActionSubscriber
  module Decoder

    def payload
      return @payload if @payload

      if callable = ::ActionSubscriber.config.decoder[content_type]
        if callable.arity == 1
          @payload = callable.call(raw_payload)
        elsif callable.arity == 3
          @payload = callable.call(routing_key, header, raw_payload)
        end
      else
        @payload = raw_payload.dup
      end

      return @payload
    end

    private

    def content_type
      header.content_type.to_s
    end
  end
end
