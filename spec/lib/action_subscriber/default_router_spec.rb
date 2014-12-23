require 'spec_helper'

describe ActionSubscriber::DefaultRouter do
  subject { described_class }

  describe '.routes_for_class' do

    context "simple subscriber" do
      class SheepSubscriber < ::ActionSubscriber::Base
        def born; end
      private
        def sheared; end
      end

      it "generates a list of routes, skips private methods" do
        routes = subject.routes_for_class(SheepSubscriber)
        expect(routes.first.action).to eq :born
        expect(routes.first.acknowledge_messages).to eq false
        expect(routes.first.exchange).to eq "events"
        expect(routes.first.middleware_stack).to be_a ::Middleware::Builder
        expect(routes.first.prefetch).to eq ::ActionSubscriber.configuration.prefetch
        expect(routes.first.queue).to eq "alice.sheep.born"
        expect(routes.first.routing_key).to eq "sheep.born"
        expect(routes.first.subscriber).to eq SheepSubscriber
        expect(routes.size).to eq(1)
      end
    end

    context "publisher and exchange can be set" do
      class GoatSubscriber < ::ActionSubscriber::Base
        exchange "actions"
        publisher "bob"

        def ate; end
      end

      let(:routes) { subject.routes_for_class(GoatSubscriber) }

      it "uses publisher in the queue name" do
        expect(routes.first.queue).to eq("alice.bob.goat.ate")
      end

      it "uses the publisher in the routing key" do
        expect(routes.first.routing_key).to eq("bob.goat.ate")
      end

      it "uses the specified exchange" do
        expect(routes.first.exchange).to eq("actions")
      end
    end

    context "at_most_once!" do
      class HouseSubscriber < ::ActionSubscriber::Base
        at_most_once!

        def built; end
      end

      let(:routes) { subject.routes_for_class(HouseSubscriber) }

      it "acknowledges messages for its routes" do
        expect(routes.first.acknowledge_messages?).to eq(true)
      end

      it "defaults sets the prefetch" do
        expect(routes.first.prefetch).to eq(::ActionSubscriber.configuration.prefetch)
      end

      it "adds the at_most_once middleware to its stack" do
        expect(routes.first.middleware_stack.delete(::ActionSubscriber::Middleware::AtMostOnce)).not_to eq nil
      end
    end

    context "at_least_once!" do
      class SamuraSubscriber < ::ActionSubscriber::Base
        at_least_once!

        def forged; end
      end

      let(:routes) { subject.routes_for_class(SamuraSubscriber) }

      it "acknowledges messages for its routes" do
        expect(routes.first.acknowledge_messages?).to eq(true)
      end

      it "defaults sets the prefetch" do
        expect(routes.first.prefetch).to eq(::ActionSubscriber.configuration.prefetch)
      end

      it "adds the at_least_once middleware to its stack" do
        expect(routes.first.middleware_stack.delete(::ActionSubscriber::Middleware::AtLeastOnce)).not_to eq nil
      end
    end
  end
end
