describe ActionSubscriber::Middleware::Stack do
  subject { ::ActionSubscriber::Middleware.initialize_stack }

  context "#forked" do
    let(:forked_stack) { subject.forked }

    it "duplicates the stack without modifying original" do
      class A; end;
      forked_stack.use(A)
      expect(forked_stack.instance_variable_get(:@stack).object_id).to_not eq subject.instance_variable_get(:@stack).object_id
      expect(forked_stack.instance_variable_get(:@stack).map(&:first)).to include(A)
      expect(subject.instance_variable_get(:@stack).map(&:first)).to_not include(A)
    end
  end
end
