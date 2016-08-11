require 'fileutils'
require 'securerandom'
require 'tmpdir'

describe 'using a packaged version of the buildpack' do
  let(:version) { File.open('VERSION').read }
  let(:filename) { "guarddog_buildpack-cached-v#{version}.zip" }
  let(:cf_api) { ENV.fetch('CF_API') }
  let(:cf_username) { ENV.fetch('CF_USERNAME') }
  let(:cf_password) { ENV.fetch('CF_PASSWORD') }
  let(:app_domain) { ENV.fetch('APP_DOMAIN') }
  let(:uuid) { "guarddog-#{SecureRandom.uuid}" }
  let(:cf_home) { Dir.tmpdir }
  let(:org) { uuid }
  let(:space) { uuid }

  before(:each) do
    ENV['CF_HOME'] = cf_home
    `cf`
    expect($?.success?).to be_truthy, 'CF CLI should be available'
    expect(`cf buildpacks`).to_not include('guarddog'), 'Buildpack should not exist before test'
  end

  after(:each) do
    `cf delete-buildpack -f guarddog` rescue nil
    `cf delete-org -f #{org}` rescue nil
    File.delete(filename) rescue nil
    FileUtils.rm_rf(cf_home)
  end

  it 'can be created' do
    `buildpack-packager --cached --use-custom-manifest spec/integration/fixtures/buildpack-manifest.yml`
    expect($?.success?).to be_truthy
    expect(File).to exist(filename)

    `cf api #{cf_api} --skip-ssl-validation`
    output = `cf auth #{cf_username} #{cf_password}`
    expect(output).to include("Authenticating...\nOK")
    expect($?.success?).to be_truthy

    `cf create-buildpack guarddog #{filename} 999 --enable`
    expect($?.success?).to be_truthy

    expect(`cf create-org #{org}`).to include('OK')
    `cf target -o #{org}`
    expect(`cf create-space #{space}`).to include('OK')
    `cf target -s #{space}`

    system('cf push test-app -p spec/integration/fixtures/app --no-start')
    expect($?.success?).to be_truthy

    system("cf set-health-check test-app none")
    expect($?.success?).to be_truthy

    system("cf start test-app")
    expect($?.success?).to be_truthy

    output = `cf ssh test-app --command "ls -la app/"`
    expect(output).to include('.guarddog')
  end
end