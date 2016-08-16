require 'fileutils'
require 'securerandom'
require 'tmpdir'

describe 'using a packaged version of the buildpack', :if => ENV["CREATE_BUILDPACK"].nil?  do
  let(:version) { File.open('VERSION').read }
  let(:filename) { "guarddog_buildpack-cached-v#{version}.zip" }
  let(:cf_api) { ENV.fetch('CF_API') }
  let(:cf_username) { ENV.fetch('CF_USERNAME') }
  let(:cf_password) { ENV.fetch('CF_PASSWORD') }
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
    `cf delete -f #{uuid}` rescue nil
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

    system('cf push #{uuid} -p spec/integration/fixtures/app --no-start')
    expect($?.success?).to be_truthy

    system("cf set-health-check #{uuid} none")
    expect($?.success?).to be_truthy

    system("cf start #{uuid}")
    expect($?.success?).to be_truthy

    output = `cf ssh #{uuid} --command "ls -la app/"`
    expect(output).to include('.guarddog')
  end
end

describe 'using a remote version of the buildpack', :if => !ENV["CREATE_BUILDPACK"].nil? do
  let(:cf_api) { ENV.fetch('CF_API_REMOTE') }
  let(:cf_username) { ENV.fetch('CF_USERNAME_REMOTE') }
  let(:cf_password) { ENV.fetch('CF_PASSWORD_REMOTE') }
  let(:cf_home) { Dir.tmpdir }
  let(:org) { ENV.fetch('CF_ORG_REMOTE') }
  let(:space) { ENV.fetch('CF_SPACE_REMOTE') }
  let(:uuid) { "guarddog-#{SecureRandom.uuid}" }
  let(:guarddog_buildpack_uri) { ENV.fetch('GD_BUILDPACK_URI') }

  before(:each) do
    ENV['CF_HOME'] = cf_home
    `cf`
    expect($?.success?).to be_truthy, 'CF CLI should be available'
    expect(`cf buildpacks`).to_not include('guarddog'), 'Buildpack should not exist before test'
  end

  after(:each) do
    `cf delete-buildpack -f guarddog` rescue nil
    `cf delete-org -f #{org}` rescue nil
    `cf delete -f #{uuid}` rescue nil
    File.delete(filename) rescue nil
    FileUtils.rm_rf(cf_home)
  end

  it 'can be used' do

    `cf api #{cf_api} --skip-ssl-validation`
    output = `cf auth #{cf_username} #{cf_password}`
    expect(output).to include("Authenticating...\nOK")
    expect($?.success?).to be_truthy

    expect(`cf target -o #{org}`).to_not include('FAILED')
    expect(`cf target -s #{space}`).to_not include('FAILED')

    system("cf push #{uuid} -p spec/integration/fixtures/app -b #{guarddog_buildpack_uri} --no-start")
    expect($?.success?).to be_truthy

    system("cf set-health-check #{uuid} none")
    expect($?.success?).to be_truthy

    system("cf start #{uuid}")
    expect($?.success?).to be_truthy

    output = `cf ssh #{uuid} --command "ls -la app/"`
    expect(output).to include('.guarddog')
  end
end
