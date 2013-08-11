module ActionSubscriber
  module Decoder

    def payload
      return @payload if @payload

      if callable = ::ActionSubscriber.config.decoder[content_type]
        @payload = callable.call(raw_payload)
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
