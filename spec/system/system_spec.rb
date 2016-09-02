require 'fileutils'
require 'rest-client'
require 'securerandom'
require 'tmpdir'
require 'wait_until'

describe 'GuardDog with multi-buildpack' do
  let(:cf_api) { ENV.fetch('CF_API') }
  let(:cf_username) { ENV.fetch('CF_USERNAME') }
  let(:cf_password) { ENV.fetch('CF_PASSWORD') }
  let(:org) { ENV.fetch('CF_ORG') }
  let(:space) { ENV.fetch('CF_SPACE') }
  let(:app_domain) { ENV.fetch('APP_DOMAIN') }
  let(:app_name) { "#{language}-guarddog-test-app-#{SecureRandom.uuid}" }
  let(:git_branch) { ENV.fetch('GIT_BRANCH') }
  let(:multi_buildpack_uri) { "#{ENV.fetch('MULTI_BUILDPACK_URI')}" }
  let(:guarddog_buildpack_uri) { "#{ENV.fetch('GD_BUILDPACK_URI')}##{git_branch}" }
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

    it 'runs the app behind HAProxy' do
      write_buildpacks_file(app_path, 'https://github.com/cloudfoundry/python-buildpack.git#master')
      push_and_check_if_diego? ? start_diego_app : start_dea_app
      expect_app_requires_basic_auth
      expect_app_returns_hello_world
    end
  end

  context 'when pushing a Ruby app' do
    let(:language) { 'ruby' }
    let(:app_path) { 'spec/system/fixtures/ruby-hello-world' }

    it 'runs the app behind HAProxy' do
      write_buildpacks_file(app_path, 'https://github.com/cloudfoundry/ruby-buildpack.git#master')
      push_and_check_if_diego? ? start_diego_app : start_dea_app
      expect_app_requires_basic_auth
      expect_app_returns_hello_world

      execute_post_and_expect("crash", RestClient::BadGateway)
      expect_command_to_succeed_and_output("cf events #{app_name}", 'app.crash')

      wait_for_app_recovery
      expect_app_returns_hello_world

      execute_post_and_expect("kill-haproxy", RestClient::BadGateway)
      expect_command_to_succeed_and_output("cf events #{app_name}", 'app.crash')

      wait_for_app_recovery
      expect_app_returns_hello_world

      execute_post_and_expect("exit", RestClient::InternalServerError)
      output = `cf events #{app_name}`
      expect($?.success?).to be_truthy
      expect(output.scan('app.crash').size).to eq(3)
    end
  end

  context 'when the app cannot return a response before the configured timeout' do
    let(:language) { 'ruby' }
    let(:app_path) { 'spec/system/fixtures/ruby-slow-app' }

    it "returns a 503" do
      write_buildpacks_file(app_path, 'https://github.com/cloudfoundry/ruby-buildpack.git#master')
      diego = push_and_check_if_diego?
      expect_command_to_succeed("cf set-env #{app_name} TIMEOUT_SERVER 15s")
      diego ? start_diego_app : start_dea_app

      thread = Thread.new do
        response = make_slow_request(25)
        expect(response.body).to eq('I slept!')
      end

      # Saw race conditions where request in separate thread was processed after
      # request in main thread below
      Wait.until_true!(timeout_in_seconds: 15) {
        `cf logs #{app_name} --recent`.include?('Requests in flight: 1')
      }

      make_requests_and_expect(10, 503)
    end
  end

  context "when the app is requested more times than it can handle" do
    let(:language) { 'ruby' }
    let(:app_path) { 'spec/system/fixtures/ruby-slow-app' }
    let(:procfile_path) { File.join(app_path, 'Procfile') }

    after(:each) do
      FileUtils.rm_rf(procfile_path)
    end

    it "the number of requests is throttled by haproxy" do
      write_buildpacks_file(app_path, 'https://github.com/cloudfoundry/ruby-buildpack.git#master')

      File.open(File.join(app_path, 'Procfile'), 'w') { |file|
        file.puts 'web: rackup -p $PORT -s puma -O Threads=10:10'
      }

      diego = push_and_check_if_diego?
      expect_command_to_succeed("cf set-env #{app_name} TIMEOUT_SERVER 15s")
      expect_command_to_succeed("cf set-env #{app_name} MAXCONN 1")
      diego ? start_diego_app : start_dea_app

      2.times do
        Thread.new do
          RestClient::Request.execute(method: :get, url: "https://#{app_name}.#{app_domain}/slow?delay=5", verify_ssl: OpenSSL::SSL::VERIFY_NONE, user: 'foo', password: 'bar')
        end
      end

      logs = `cf logs #{app_name} --recent`
      expect(logs).to include('Requests in flight: 1')
      expect(logs).to_not include('Requests in flight: 2')
    end
  end

  def write_buildpacks_file(fixture_dir, buildpack_url)
    File.open(multi_buildpack_conf_path, 'w') { |file|
      file.puts buildpack_url
      file.puts guarddog_buildpack_uri
    }
  end

  def push_and_check_if_diego?
    expect_command_to_succeed("cf push #{app_name} -p #{app_path} -b #{multi_buildpack_uri} --no-start")
    app_info = `cf curl /v2/apps/$(cf app #{app_name} --guid)`
    app_info.include? '"diego": true'
  end

  def push_and_crash?
    expect_command_to_succeed("cf push #{app_name} -p #{app_path} -b #{multi_buildpack_uri} --no-start -c './mininit.sh & while ! nc -z localhost $PORT; do sleep 0.2; done; sleep 5; pkill -f haproxy; sleep inf'")
    app_info = `cf curl /v2/apps/$(cf app #{app_name} --guid)`
    app_info.include? '"diego": true'
  end

  def expect_app_requires_basic_auth
    expect{RestClient::Request.execute(method: :get, url: "https://#{app_name}.#{app_domain}/", verify_ssl: OpenSSL::SSL::VERIFY_NONE)}.to raise_error { |error|
      expect(error.response.code).to be(401)
    }
  end

  def expect_app_returns_hello_world
    response = RestClient::Request.execute(method: :get, url: "https://#{app_name}.#{app_domain}", verify_ssl: OpenSSL::SSL::VERIFY_NONE, user: 'foo', password: 'bar')
    expect(response.code).to be(200)
    expect(response.body).to include('Hello, World!')
  end

  def start_diego_app
    expect_command_to_succeed("cf set-health-check #{app_name} none")
    expect_command_to_succeed("cf start #{app_name}")
    expect_command_to_succeed_and_output("cf app #{app_name}", "buildpack: #{multi_buildpack_uri}")
  end

  def start_dea_app
    expect_command_to_succeed("cf start #{app_name}")
    expect_command_to_succeed_and_output("cf app #{app_name}", "buildpack: #{multi_buildpack_uri}")
  end

  def wait_for_app_recovery
    Wait.until!(timeout_in_seconds: 120) {
        200 == RestClient::Request.execute(method: :get, url: "https://#{app_name}.#{app_domain}", verify_ssl: OpenSSL::SSL::VERIFY_NONE, user: 'foo', password: 'bar').code
    }
  end

  def execute_post_and_expect(path, exception)
    expect{
      RestClient::Request.execute(method: :post, url: "https://#{app_name}.#{app_domain}/#{path}", verify_ssl: OpenSSL::SSL::VERIFY_NONE, user: 'foo', password: 'bar')
    }.to raise_error(exception)
  end

  def make_slow_request(delay)
    # Using curl as RestClient would not reliably send requests in order!
    code = `curl -so/dev/null --user foo:bar -w %{http_code} -k https://#{app_name}.#{app_domain}/slow?delay=#{delay}`
    code.to_i
  end

  def make_requests_and_expect(number, code)
    for i in 1..number
      Thread.new do
        observed = make_slow_request(0)
        expect(observed).to eq(code), "Request #{i} returned #{observed}"
      end
    end
  end
end
