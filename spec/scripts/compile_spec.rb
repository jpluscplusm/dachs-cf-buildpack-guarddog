require 'fileutils'
require 'tmpdir'

describe 'bin/compile' do

  current_dir = File.dirname(__FILE__)

  before(:all) do
    @app_dir = Dir.mktmpdir('app')
    FileUtils.cp("#{current_dir}/fixtures/app_release.out", "#{@app_dir}/app_release.out")
    @cache_dir = File.join(Dir.tmpdir, ('guarddog-cache'))
    @guarddog_file = File.join(@app_dir, '.guarddog')
    @haproxy = File.join(@app_dir, 'haproxy')
    system("ruby bin/compile #{@app_dir} #{@cache_dir}")
  end

  after(:all) do
    FileUtils.rm_rf(@app_dir)
    FileUtils.rm("mininit.sh")
  end

  it 'writes the .guarddog file' do
    expect(File.exists?(@guarddog_file)).to be_truthy
  end

  it 'downloads haproxy' do
    expect(File.exists?(@haproxy)).to be_truthy
  end
end
