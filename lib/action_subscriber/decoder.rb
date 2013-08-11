module ActionSubscriber
  module Decoder

    def payload
      @payload ||= case
      when json_payload?
        ::ActionSubscriber::Serializers::JSON.deserialize(raw_payload)
      when proto_payload?
        ::ActionSubscriber::Serializers::Protobuf.deserialize(raw_payload)
      when text_payload?
        raw_payload.dup
      else
        raw_payload.dup
      end
    end

    private

    def content_type
      header.content_type
    end

    def json_payload?
      !!(content_type =~ /application\/json/i)
    end

    def proto_payload?
      !!(content_type =~ /application\/protocol-buffers/i)
    end

    def text_payload?
      !!(content_type =~ /text/i)
    end
  end
end
