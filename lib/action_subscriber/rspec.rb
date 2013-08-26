module ActionSubscriber
  module RSpec
    # Create a new subscriber instance. Available options are:
    #
    #  * :class - the class constant corresponding to the subscriber. `described_class` is the default.
    #  * :header - the header object to pass into the instance.
    #  * :raw_payload - the raw payload object to pass into the instnace.
    #
    # Example
    #
    #   describe UserSubscriber do
    #     subject { mock_subscriber }
    #
    #     it 'logs the user create event' do
    #       SomeLogger.should_receive(:log)
    #       subject.created(proto)
    #     end
    #   end
    #
    def mock_subscriber(opts = {})
      header = opts.fetch(:header) { double('header').as_null_object }
      payload = opts.fetch(:payload) { double('payload').as_null_object }
      raw_payload = opts.fetch(:raw_payload) { double('raw payload').as_null_object }

      subscriber_class = opts.fetch(:class) { described_class }

      return subscriber_class.new(header, raw_payload)
    end

  end
end
