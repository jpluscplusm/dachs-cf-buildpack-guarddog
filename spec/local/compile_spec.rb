require 'fileutils'
require 'tmpdir'

describe 'bin/compile' do

  before(:all) do
    @tmpdir = Dir.mktmpdir
    @guarddog_file = File.join(@tmpdir, '.guarddog')
    @haproxy = File.join(@tmpdir, 'haproxy')
    @nginx = File.join(@tmpdir, 'nginx.tgz')
    system("ruby bin/compile #{@tmpdir}")
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
    expect(File.exists?(@nginx)).to be_truthy
  end
end
