require 'fileutils'
require 'tmpdir'

describe 'bin/compile' do
  let(:tmpdir) { Dir.tmpdir }
  let(:written_file) { File.join(tmpdir, '.guarddog') }

  after(:each) do
    FileUtils.rm(written_file)
  end

  it 'writes a file' do
    expect(system("bin/compile #{tmpdir}")).to be_truthy
    expect(File.exists?(written_file)).to be_truthy
  end
end