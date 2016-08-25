describe WaitUntil::Wait do

  let(:block) { lambda { "some block" } }
  let(:args)  { {} }

  shared_examples_for "a wait method that uses an operation to determine if it eventually succeeds" do

    let(:eventually_true_flag) { true }
    let(:failure_message)      { "some failure message" }
    let(:operation)            do
      instance_double(WaitUntil::Operation, eventually_true?: eventually_true_flag, failure_message: failure_message)
    end

    before(:example) { allow(WaitUntil::Operation).to receive(:new).and_return(operation) }

    it "creates an operation representing the call" do
      expect(WaitUntil::Operation).to receive(:new).with(args)

      subject
    end

    it "determines if the operation eventually returns true" do
      expect(operation).to receive(:eventually_true?)

      subject
    end

    context "when the operation is eventually true" do

      let(:eventually_true_flag) { true }

      it "executes without error" do
        expect(lambda { subject }).to_not raise_error
      end

    end

    context "when the operation is never eventually true" do

      let(:eventually_true_flag) { false }

      it "raises an error with the operations failure message" do
        expect(lambda { subject }).to raise_error(failure_message)
      end

    end

  end

  describe "::until_true!" do

    subject { described_class.until_true!(args, &block) }

    it_behaves_like "a wait method that uses an operation to determine if it eventually succeeds"

    context "when the block returns true" do

      let(:block) { lambda { true } }

      it "executes without error" do
        expect(lambda { subject }).to_not raise_error
      end

    end

    context "when the block returns false" do

      let(:block) { lambda { false } }

      it "raises an error" do
        expect(lambda { subject }).to raise_error(/timed-out/i)
      end

    end

  end

  describe "::until_false!" do

    subject { described_class.until_false!(args, &block) }

    it_behaves_like "a wait method that uses an operation to determine if it eventually succeeds"

    context "when the block returns false" do

      let(:block) { lambda { false } }

      it "executes without error" do
        expect(lambda { subject }).to_not raise_error
      end

    end

    context "when the block returns true" do

      let(:block) { lambda { true } }

      it "raises an error" do
        expect(lambda { subject }).to raise_error(/timed-out/i)
      end

    end

  end

  describe "::until!" do

    subject { described_class.until!(args, &block) }

    it_behaves_like "a wait method that uses an operation to determine if it eventually succeeds"

    context "when the block executes without error" do

      let(:block) { lambda { "does not raise an error" } }

      it "executes without error" do
        expect(lambda { subject }).to_not raise_error
      end

    end

    context "when the block raises an error" do

      let(:block) { lambda { raise "forced error" } }

      it "raises an error" do
        expect(lambda { subject }).to raise_error(/timed-out/i)
      end

    end

  end

end
