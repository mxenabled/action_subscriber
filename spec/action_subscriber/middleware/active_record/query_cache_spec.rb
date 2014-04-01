require 'spec_helper'
require 'action_subscriber/middleware/active_record/query_cache'

describe ActionSubscriber::Middleware::ActiveRecord::QueryCache do
  include_context 'action subscriber middleware env'

  let(:connection) { double(:connection, :query_cache_enabled => true) }

  before do
    connection.stub(:clear_query_cache)
    connection.stub(:disable_query_cache!)
    connection.stub(:enable_query_cache!)

    ActiveRecord::Base.better_stub(:connection).and_return(connection)
    ActiveRecord::Base.better_stub(:connection_id)
  end

  subject { described_class.new(app) }

  it_behaves_like 'an action subscriber middleware'

  it "enables the query cache" do
    connection.should_receive(:enable_query_cache!)
    subject.call(env)
  end

  it "clears the query cache" do
    connection.should_receive(:clear_query_cache)
    subject.call(env)
  end

  context "when the query cache is already enabled" do
    before { connection.stub(:query_cache_enabled).and_return(true) }

    it "does not disable the query cache" do
      connection.should_not_receive(:disable_query_cache!)
      subject.call(env)
    end
  end

  context "when the query cache is not already enabled" do
    before { connection.stub(:query_cache_enabled).and_return(false) }

    it "does disable the query cache" do
      connection.should_receive(:disable_query_cache!)
      subject.call(env)
    end
  end
end
