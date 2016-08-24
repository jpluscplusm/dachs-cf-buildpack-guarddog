require 'fileutils'
require 'tmpdir'

describe 'bin/compile' do

  current_dir = File.dirname(__FILE__)

  before(:all) do
    @app_dir = Dir.mktmpdir('app')
    FileUtils.cp("#{current_dir}/fixtures/app_release.out", "#{@app_dir}/app_release.out")
    @cache_dir = File.join(Dir.tmpdir, ('guarddog-cache'))
    @mininit_file = File.join(@app_dir, 'mininit.sh')
    @haproxy = File.join(@app_dir, 'haproxy')
    system("ruby bin/compile #{@app_dir} #{@cache_dir}")
  end

  after(:all) do
    FileUtils.rm_rf(@app_dir)
  end

  it 'writes the mininit.sh file' do
    expect(File.exists?(@mininit_file)).to be_truthy
  end

  it 'downloads haproxy' do
    expect(File.exists?(@haproxy)).to be_truthy
  end
end
