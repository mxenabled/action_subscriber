require 'action_subscriber/middleware/active_record/query_cache'

describe ActionSubscriber::Middleware::ActiveRecord::QueryCache do
  include_context 'action subscriber middleware env'

  let(:connection) { double(:connection, :query_cache_enabled => true) }

  before do
    allow(connection).to receive(:clear_query_cache)
    allow(connection).to receive(:disable_query_cache!)
    allow(connection).to receive(:enable_query_cache!)

    allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
    # Rails 5 "compat"
    allow(ActiveRecord::Base).to receive(:connection_id) if ::ActiveRecord::Base.respond_to?(:connection_id)
  end

  subject { described_class.new(app) }

  it_behaves_like 'an action subscriber middleware'

  it "enables the query cache" do
    expect(connection).to receive(:enable_query_cache!)
    subject.call(env)
  end

  it "clears the query cache" do
    expect(connection).to receive(:clear_query_cache)
    subject.call(env)
  end

  context "when the query cache is already enabled" do
    before { allow(connection).to receive(:query_cache_enabled).and_return(true) }

    it "does not disable the query cache" do
      expect(connection).to_not receive(:disable_query_cache!)
      subject.call(env)
    end
  end

  context "when the query cache is not already enabled" do
    before { allow(connection).to receive(:query_cache_enabled).and_return(false) }

    it "does disable the query cache" do
      expect(connection).to receive(:disable_query_cache!)
      subject.call(env)
    end
  end
end
