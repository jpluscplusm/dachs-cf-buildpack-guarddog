require 'fileutils'
require 'tmpdir'

describe 'bin/compile' do

  before(:all) do
    @tmpdir = Dir.mktmpdir('app')
    @cache_dir = Dir.mktmpdir('cache')
    @guarddog_file = File.join(@tmpdir, '.guarddog')
    @haproxy = File.join(@tmpdir, 'haproxy')
    system("ruby bin/compile #{@tmpdir} #{@cache_dir}")
  end

  after(:all) do
    FileUtils.rm_rf(@tmpdir)
  end

  it 'writes the .guarddog file' do
    expect(File.exists?(@guarddog_file)).to be_truthy
  end

  it 'downloads haproxy' do
    expect(File.exists?(@haproxy)).to be_truthy
  end

  it 'downloads nginx' do
    expect(File.exists?(File.join(@cache_dir, 'nginx.tgz'))).to be_truthy
  end

  it 'untars nginx' do
    expect(Dir.exists?(File.join(@tmpdir, 'nginx'))).to be_truthy
    expect(File.exists?(File.join(@tmpdir, 'nginx', 'sbin', 'nginx'))).to be_truthy
  end
end
