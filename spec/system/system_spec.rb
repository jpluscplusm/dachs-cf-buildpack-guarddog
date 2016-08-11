require 'fileutils'
require 'rest-client'
require 'securerandom'
require 'tmpdir'

describe 'GuardDog with multi-buildpack' do
  let(:cf_api) { ENV.fetch('CF_API') }
  let(:cf_username) { ENV.fetch('CF_USERNAME') }
  let(:cf_password) { ENV.fetch('CF_PASSWORD') }
  let(:org) { ENV.fetch('CF_ORG') }
  let(:space) { ENV.fetch('CF_SPACE') }
  let(:app_domain) { ENV.fetch('APP_DOMAIN') }
  let(:app_name) { "guarddog-test-app-#{SecureRandom.uuid}" }
  let(:multi_buildpack_uri) { ENV.fetch('MULTI_BUILDPACK_URI') }
  let(:guarddog_buildpack_uri) { ENV.fetch('GD_BUILDPACK_URI') }
  let(:cf_home) { Dir.tmpdir }
  let(:fixture_dir) { 'spec/system/fixtures/hello-python-web' }
  let(:multi_buildpack_conf_path) { File.join(fixture_dir, '.buildpacks') }

  before(:each) do
    ENV['CF_HOME'] = cf_home
    File.open(multi_buildpack_conf_path, 'w') { |file|
      file.puts guarddog_buildpack_uri
      file.puts 'https://github.com/cloudfoundry/python-buildpack.git'
    }
  end

  after(:each) do
    `cf delete -f #{app_name}`
    FileUtils.rm_rf cf_home
    FileUtils.rm_rf multi_buildpack_conf_path
  end

  it 'allows regular apps to run whilst still providing .guarddog file' do
    `cf login -a #{cf_api} -u #{cf_username} -p #{cf_password} -o #{org} -s #{space} --skip-ssl-validation`
    expect($?.success?).to be_truthy, 'Login should have worked'

    `cf push #{app_name} -p spec/system/fixtures/hello-python-web -b #{multi_buildpack_uri} --no-start`
    `cf set-health-check #{app_name} none`
    push_success = system("cf start #{app_name}")
    expect(push_success).to be_truthy

    expect(`cf app #{app_name}`).to include("buildpack: #{multi_buildpack_uri}")

    response = RestClient::Request.execute(method: :get, url: "https://#{app_name}.#{app_domain}", verify_ssl: OpenSSL::SSL::VERIFY_NONE)
    expect(response.code).to be(200)
    expect(response.body).to eq('Hello, World!')

    output = `cf ssh #{app_name} --command "ls -la app/"`
    expect(output).to include('.guarddog')
  end
end