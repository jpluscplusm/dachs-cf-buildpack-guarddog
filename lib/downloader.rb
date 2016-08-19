module Downloader
  def self.download(host, path, destination)
    Net::HTTP.start(host) do |http|
      resp = http.get(path)
      open(destination, 'wb') do |file|
        file.write(resp.body)
      end
    end

    puts "Download of #{host}#{path} to #{destination} finished"
  end
end
