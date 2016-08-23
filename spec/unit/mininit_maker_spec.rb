require 'mininit_maker'

RSpec.describe MininitMaker do
  current_dir = File.dirname(__FILE__)
  let(:file) { "mininit.sh" }

  subject { described_class.new(app_release) }

  after(:each) do
    File.delete(file) if File.exist?(file)
  end

  describe "#create" do
    context "when there are config variables" do
      let(:app_release) { "#{current_dir}/fixtures/app_release.out" }
      let(:contents) { IO.read("#{current_dir}/fixtures/mininit_contents") }

      it 'produces a mininit script' do
        expect(File).to_not exist(file)
        subject.create
        expect(File).to exist(file)
        expect(File.read(file)).to match(contents)
      end
    end

    context "when there aren't any config variables" do
      let(:app_release) { "#{current_dir}/fixtures/app_release2.out" }
      let(:contents) { IO.read("#{current_dir}/fixtures/mininit_contents2") }

      it 'produces a mininit script' do
        expect(File).to_not exist(file)
        subject.create
        expect(File).to exist(file)
        expect(File.read(file)).to match(contents)
      end
    end
  end
end