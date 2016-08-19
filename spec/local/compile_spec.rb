require 'fileutils'
require 'tmpdir'

describe 'bin/compile' do

  before(:all) do
    @app_dir = Dir.mktmpdir('app')
    @cache_dir = File.join(Dir.tmpdir, ('guarddog-cache'))
    @guarddog_file = File.join(@app_dir, '.guarddog')
    @haproxy = File.join(@app_dir, 'haproxy')
    system("ruby bin/compile #{@app_dir} #{@cache_dir}")
  end

  after(:all) do
    FileUtils.rm_rf(@app_dir)
  end

  it 'writes the .guarddog file' do
    expect(File.exists?(@guarddog_file)).to be_truthy
  end

  it 'downloads haproxy' do
    expect(File.exists?(@haproxy)).to be_truthy
  end
end
