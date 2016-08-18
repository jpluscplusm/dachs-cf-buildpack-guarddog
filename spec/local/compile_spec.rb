require 'fileutils'
require 'tmpdir'

describe 'bin/compile' do

  before(:all) do
    @app_dir = Dir.mktmpdir('app')
    @cache_dir = Dir.mktmpdir('cache')
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

  it 'downloads nginx tarball' do
    expect(File.exists?(File.join(@cache_dir, 'nginx.tgz'))).to be_truthy
  end

  it 'untars nginx executable' do
    expect(Dir.exists?(File.join(@app_dir, 'nginx'))).to be_truthy
    expect(File.exists?(File.join(@app_dir, 'nginx', 'sbin', 'nginx'))).to be_truthy
  end
end
