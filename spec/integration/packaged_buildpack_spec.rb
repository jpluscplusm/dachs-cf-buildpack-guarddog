describe 'using a packaged version of the buildpack' do
  let(:version) { File.open('VERSION').read }
  let(:filename) { "guarddog_buildpack-cached-v#{version}.zip" }

  it 'can be created' do
    `buildpack-packager --cached --use-custom-manifest spec/integration/fixtures/buildpack-manifest.yml`
    expect($?.success?).to be_truthy

    expect(File).to exist(filename)
    File.delete(filename)
  end
end