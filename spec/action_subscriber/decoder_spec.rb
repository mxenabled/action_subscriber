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

    context 'when the content type has an associated decoder' do
      context "when the content type is json" do
        let(:content_type) { "application/json" }

        it "deserializes JSON" do
          ::JSON.better_receive(:parse).with(raw_payload)
          subject.payload
        end
      end

      context "when the content type is text" do
        let(:content_type) { "text/plain" }

        it "returns the payload" do
          subject.payload.should eq(raw_payload)
        end
      end

      context 'callable arity' do
        let(:content_type) { 'foo' }
        let(:routing_key) { 'foo.bar.baz' }

        before { TestDecoder.any_instance.stub(:routing_key).and_return(routing_key) }
        before { ActionSubscriber.config.add_decoder(content_type => decoder) }

        context 'when the decoder\'s arity is 1' do
          let(:decoder) { lambda { |payload| [ payload ] } }

          it 'calls the decoder with the payload' do
            subject.payload.should eq [ raw_payload ]
          end
        end

        context 'when the decoder\'s arity is 3' do
          let(:decoder) {
            lambda { |_routing_key, _headers, _payload| [ _routing_key, _headers, _payload ] }
          }

          it 'calls the decoder with the routing key, header, and payload' do
            subject.payload.should eq [ routing_key, header, raw_payload ]
          end
        end
      end
    end

    context "when the content type does not have an associated decoder" do
      let(:content_type) { "some mime type" }

      it "returns the payload" do
        subject.payload.should eq(raw_payload)
      end
    end
  end
end
