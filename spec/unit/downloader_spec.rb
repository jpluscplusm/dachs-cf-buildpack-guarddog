require 'downloader'
require 'webmock/rspec'

describe Downloader do
  describe '.download' do
    it 'downloads haproxy' do
      stub = stub_request(:get, 's3-eu-west-1.amazonaws.com/dachs-haproxy-build/haproxy').
        to_return(body: 'file-contents')

      file = double('file')
      expect(Downloader).to receive(:open).with('destination/haproxy', 'wb').and_yield(file)
      expect(file).to receive(:write).with('file-contents')

      Downloader.download('s3-eu-west-1.amazonaws.com', '/dachs-haproxy-build/haproxy', 'destination/haproxy')
      expect(stub).to have_been_requested
    end
  end
end
