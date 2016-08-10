require 'fileutils'
require 'tmpdir'

describe 'bin/compile' do
  let(:tmpdir) { Dir.tmpdir }
  let(:destination) { File.join(tmpdir, 'compile') }
  let(:written_file) { File.join(tmpdir, '.guarddog') }

  before(:each) do
    FileUtils.copy('bin/compile', destination)
  end

  after(:each) do
    FileUtils.rm(destination)
  end


  it 'writes a file' do
    expect(system(destination)).to be_truthy
    expect(File.exists?(written_file)).to be_truthy
  end
end