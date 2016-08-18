require 'fileutils'
require 'tmpdir'

describe 'bin/compile' do

  before(:all) do
    @tmpdir = Dir.mktmpdir
    @written_file = File.join(@tmpdir, '.guarddog')
    @haproxy = File.join(@tmpdir, 'haproxy')
    system("ruby bin/compile.rb #{@tmpdir}")
  end

  after(:all) do
    FileUtils.rm_rf(@tmpdir)
  end

  it 'writes a file' do
    expect(File.exists?(@written_file)).to be_truthy
  end

  it 'downloads haproxy' do
    expect(File.exists?(@haproxy)).to be_truthy
  end

end
