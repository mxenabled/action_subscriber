require 'spec_helper'

describe ActionSubscriber::Middleware::Decoder do
  include_context 'action subscriber middleware env'

  let(:encoded_payload) { env.encoded_payload }

  subject { described_class.new(app) }

  it_behaves_like 'an action subscriber middleware'

  before { message_properties[:content_type] = "application/foo"}

  context "when the content type has an associated decoder" do
    let(:decoder) { { 'application/foo' => lambda { |_| payload } } }
    let(:payload) { double(:payload) }

    before { allow(ActionSubscriber.config).to receive(:decoder).and_return(decoder) }

    it "decodes the payload" do
      allow(env).to receive(:payload=).with(payload)
      subject.call(env)
    end
  end

  context "when the content type does not have an associated decoder" do
    it "dups the payload" do
      allow(env).to receive(:payload=).with(encoded_payload)
      subject.call(env)
    end
  end
end
