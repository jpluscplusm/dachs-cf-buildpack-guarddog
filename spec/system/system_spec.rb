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
  let(:app_name) { "#{language}-guarddog-test-app-#{SecureRandom.uuid}" }
  let(:multi_buildpack_uri) { ENV.fetch('MULTI_BUILDPACK_URI') }
  let(:guarddog_buildpack_uri) { ENV.fetch('GD_BUILDPACK_URI') }
  let(:multi_buildpack_conf_path) { File.join(app_path, '.buildpacks') }


  before(:each) do
    @cf_home = Dir.mktmpdir
    ENV['CF_HOME'] = @cf_home

    login_result = `cf login -a #{cf_api} -u #{cf_username} -p #{cf_password} -o #{org} -s #{space} --skip-ssl-validation`
    expect($?.success?).to be_truthy, "#{login_result}"
  end

  after(:each) do
    `cf delete -f #{app_name}`
    FileUtils.rm_rf @cf_home
    FileUtils.rm_rf multi_buildpack_conf_path
  end

  context 'when pushing a Python app' do
    let(:language) { 'python' }
    let(:app_path) { 'spec/system/fixtures/hello-python-web' }

    it 'allows regular apps to run whilst still providing .guarddog file' do
      write_buildpacks_file(app_path, 'https://github.com/cloudfoundry/python-buildpack.git#master')
      push_and_check_if_diego? ? start_diego_app(app_path) : start_dea_app(app_path)
      expect_app_returns_hello_world
    end
  end

  context 'when pushing a Ruby app' do
    let(:language) { 'ruby' }
    let(:app_path) { 'spec/system/fixtures/ruby-hello-world' }

    it 'allows a ruby app to run whilst providing a .guarddog file' do
      write_buildpacks_file(app_path, 'https://github.com/cloudfoundry/ruby-buildpack.git#master')
      push_and_check_if_diego? ? start_diego_app(app_path) : start_dea_app(app_path)
      expect_app_returns_hello_world
    end
  end

  def write_buildpacks_file(fixture_dir, buildpack_url)
    File.open(multi_buildpack_conf_path, 'w') { |file|
      file.puts guarddog_buildpack_uri
      file.puts buildpack_url
    }
  end

  def push_and_check_if_diego?
    expect_command_to_succeed("cf push #{app_name} -p #{app_path} -b #{multi_buildpack_uri} --no-start")
    app_info = `cf curl /v2/apps/$(cf app #{app_name} --guid)`
    app_info.include? '"diego": true'
  end

  def expect_app_returns_hello_world
    puts "https://#{app_name}.#{app_domain}"
    response = RestClient::Request.execute(method: :get, url: "https://#{app_name}.#{app_domain}", verify_ssl: OpenSSL::SSL::VERIFY_NONE)
    expect(response.code).to be(200)
    expect(response.body).to include('Hello, World!')
  end

  def start_diego_app(app_path)
    expect_command_to_succeed("cf set-health-check #{app_name} none")
    expect_command_to_succeed("cf start #{app_name}")

    expect_command_to_succeed_and_output("cf app #{app_name}", "buildpack: #{multi_buildpack_uri}")
    expect_command_to_succeed_and_output("cf ssh #{app_name} --command \"ls -la app/\"", '.guarddog')
  end

  def start_dea_app(app_path)
    expect_command_to_succeed("cf start #{app_name}")
    expect_command_to_succeed_and_output("cf app #{app_name}", "buildpack: #{multi_buildpack_uri}")
    expect_command_to_succeed_and_output("cf files #{app_name} app/", '.guarddog')
  end
end