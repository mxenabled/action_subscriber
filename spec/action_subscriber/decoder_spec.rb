require 'spec_helper'

class TestDecoder
  include ::ActionSubscriber::Decoder
end

describe ActionSubscriber::Decoder do
  describe "payload" do
    let(:content_type) { "some mime type" }
    let(:header) { OpenStruct.new(:content_type => content_type) }
    let(:raw_payload) { "some bytes" }

    before do
      TestDecoder.any_instance.stub(:header).and_return(header)
      TestDecoder.any_instance.stub(:raw_payload).and_return(raw_payload)
    end

    subject { TestDecoder.new }

    context "when the content type is json" do
      let(:content_type) { "application/json" }

      it "deserializes JSON" do
        ::ActionSubscriber::Serializers::JSON.better_receive(:deserialize).with(raw_payload)
        subject.payload
      end
    end

    context "when the content type is protobuf" do
      let(:content_type) { "application/protocol-buffers" }

      it "deserializes protobuf" do
        ::ActionSubscriber::Serializers::Protobuf.better_receive(:deserialize).with(raw_payload)
        subject.payload
      end
    end

    context "when the content type is text" do
      let(:content_type) { "text/plain" }

      it "returns the payload" do
        subject.payload.should eq(raw_payload)
      end
    end

    context "when the content type is not specified" do
      let(:content_type) { "some mime type" }

      it "returns the payload" do
        subject.payload.should eq(raw_payload)
      end
    end
  end
end
