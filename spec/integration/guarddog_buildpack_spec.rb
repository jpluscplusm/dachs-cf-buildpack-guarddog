require 'fileutils'
require 'rest-client'
require 'securerandom'
require 'tmpdir'

describe 'GuardDog buildpack alone' do
  let(:skip_setup) { ENV.fetch('SKIP_SETUP', false) }
  let(:skip_teardown) { ENV.fetch('SKIP_TEARDOWN', false) }
  let(:version) { File.open('VERSION').read }
  let(:buildpack_filename) { "guarddog_buildpack-cached-v#{version}.zip" }
  let(:cf_api) { ENV.fetch('CF_API') }
  let(:app_domain) { ENV.fetch('APP_DOMAIN') }
  let(:cf_username) { ENV.fetch('CF_USERNAME') }
  let(:cf_password) { ENV.fetch('CF_PASSWORD') }
  let(:app_name) { ENV.fetch('CF_APP', "guarddog-#{SecureRandom.uuid}") }
  let(:cf_home) { Dir.mktmpdir }
  let(:org) { ENV.fetch('CF_ORG', app_name) }
  let(:space) { ENV.fetch('CF_SPACE', app_name) }

  before(:each) do
    ENV['CF_HOME'] = cf_home
    `cf`
    expect($?.success?).to be_truthy, 'CF CLI should be available'
    unless skip_setup
      expect(`cf buildpacks`).to_not include('guarddog'), 'Buildpack should not exist before test'
    end
  end

  after(:each) do
    unless skip_teardown
      `cf delete -f #{app_name}` rescue nil
      File.delete(buildpack_filename) rescue nil
    end

    FileUtils.rm_rf(cf_home)
  end

  context 'when the buildpack is packaged', :if => ENV.fetch("CREATE_BUILDPACK") == "true"  do
    before(:each) do
      expect_command_to_succeed("cf api #{cf_api} --skip-ssl-validation")
      expect_command_to_succeed_and_output("cf auth #{cf_username} #{cf_password}", "Authenticating...\nOK")

      unless skip_setup
        expect_command_to_succeed("buildpack-packager --cached --use-custom-manifest spec/integration/fixtures/buildpack-manifest.yml")
        expect(File).to exist(buildpack_filename)

        expect_command_to_succeed("cf create-buildpack guarddog #{buildpack_filename} 999 --enable")

        expect_command_to_succeed_and_output("cf create-org #{org}", 'OK')
        expect_command_to_succeed_and_output("cf create-space #{space} -o #{org}", 'OK')
      end

      expect_command_to_succeed("cf target -o #{org}")
      expect_command_to_succeed("cf target -s #{space}")
    end

    after(:each) do
      unless skip_teardown
        `cf delete-buildpack -f guarddog` rescue nil

        if org == app_name
          `cf delete-org -f #{org}` rescue nil
        end
      end
    end

    it 'runs apps with haproxy' do
      expect_command_to_succeed("cf push #{app_name} -p spec/integration/fixtures/starting-app --no-start")
      expect_command_to_succeed("cf set-env #{app_name} TIMEOUT_SERVER 10s")
      expect_command_to_succeed("cf start #{app_name}")

      expect_command_to_succeed_and_output("cf ssh #{app_name} --command \"ls -la app/\"", 'haproxy')
      expect_hap_to_require_basic_auth
      expect_200_on_valid_auth
      expect_503_on_unresponsive_path
      expect_hap_termination_state
    end

    it 'fails if the app does not bind to a port' do
      expect_command_to_fail_and_output("cf push #{app_name} -p spec/integration/fixtures/app -t 10", "Start app timeout")
    end
  end

  context 'when the buildpack is specified by URI', :if => ENV.fetch("CREATE_BUILDPACK") == "false" do
    let(:org) { ENV.fetch('CF_ORG') }
    let(:space) { ENV.fetch('CF_SPACE') }
    let(:git_branch) { ENV.fetch('GIT_BRANCH') }
    let(:guarddog_buildpack_uri) { "#{ENV.fetch('GD_BUILDPACK_URI')}##{git_branch}" }

    before(:each) do
      expect_command_to_succeed_and_output("cf api #{cf_api} --skip-ssl-validation", "OK")
      expect_command_to_succeed_and_output("cf auth #{cf_username} #{cf_password}", "Authenticating...\nOK")

      expect_command_to_succeed("cf target -o #{org}")
      expect_command_to_succeed("cf target -s #{space}")
    end

    it 'runs apps with haproxy' do
      expect_command_to_succeed("cf push #{app_name} --no-start -p spec/integration/fixtures/starting-app -b #{guarddog_buildpack_uri}")
      expect_command_to_succeed("cf set-env #{app_name} TIMEOUT_SERVER 10s")
      expect_command_to_succeed("cf start #{app_name}")

      app_info = `cf curl /v2/apps/$(cf app #{app_name} --guid)`
      if app_info.include? '"diego": true'
        expect_command_to_succeed_and_output("cf ssh #{app_name} --command \"ls -la app/\"", 'haproxy')
      else
        expect_command_to_succeed_and_output("cf files #{app_name} app/", 'haproxy')
      end

      expect_hap_to_require_basic_auth
      expect_200_on_valid_auth
      expect_503_on_unresponsive_path
      expect_hap_termination_state
    end

    it 'fails if the app does not bind to a port' do
      expect_command_to_fail_and_output("cf push #{app_name} -p spec/integration/fixtures/app -t 10 -b #{guarddog_buildpack_uri}", "Start app timeout")
    end
  end

  def expect_hap_to_require_basic_auth
    expect{RestClient::Request.execute(method: :get, url: "https://#{app_name}.#{app_domain}/hap", verify_ssl: OpenSSL::SSL::VERIFY_NONE)}.to raise_error { |error|
      expect(error.response.code).to be(401)
    }
  end

  def expect_200_on_valid_auth
    response = RestClient::Request.execute(method: :get, url: "https://#{app_name}.#{app_domain}/hap", verify_ssl: OpenSSL::SSL::VERIFY_NONE, user: 'foo', password: 'bar')
    expect(response.code).to be(200)
  end

  def expect_503_on_unresponsive_path
   expect{RestClient::Request.execute(method: :get, url: "https://#{app_name}.#{app_domain}/", verify_ssl: OpenSSL::SSL::VERIFY_NONE, user: 'foo', password: 'bar')}.to raise_error { |error|
      expect(error.response.code).to be(503)
    }
  end

  def expect_hap_termination_state
    expect_command_to_succeed_and_output("cf logs #{app_name} --recent", "sH--")
  end
end
