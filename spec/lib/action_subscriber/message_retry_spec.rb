describe ActionSubscriber::MessageRetry do
  context ".get_last_ttl_or_default" do
    it "handles messages with no x-death header" do
      expect(described_class.get_last_ttl_or_default(nil, 50)).to eq 50
    end

    it "handles x-death headers that are pre-parsed" do
      header = [{"original-expiration" => "100", "reason" => "expired"}, {"original-expiration" => "500"}]
      expect(described_class.get_last_ttl_or_default(header, 50)).to eq 500
    end

    it "parses x-death headers that are just strings" do
      header = "[{reason=expired, original-expiration=100, count=1, exchange=events_retry_100, time=Tue Oct 20 21:18:04 MDT 2015, routing-keys=[gorby_puff.grumpy], queue=alice.gorby_puff.grumpy_retry_100},{original-expiration=200, count=2}]"
      expect(described_class.get_last_ttl_or_default(header, 50)).to eq 200
    end
  end
end
