describe WaitUntil do

  describe "when loaded" do

    it "defines the global Wait class as the WaitUntil::Wait class" do
      expect(::Wait).to eql(WaitUntil::Wait)
    end

  end

end
