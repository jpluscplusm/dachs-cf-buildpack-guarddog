require 'fileutils'
require 'rest-client'
require 'securerandom'
require 'tmpdir'

describe 'GuardDog buildpack alone' do
  let(:version) { File.open('VERSION').read }
  let(:filename) { "guarddog_buildpack-cached-v#{version}.zip" }
  let(:cf_api) { ENV.fetch('CF_API') }
  let(:app_domain) { ENV.fetch('APP_DOMAIN') }
  let(:cf_username) { ENV.fetch('CF_USERNAME') }
  let(:cf_password) { ENV.fetch('CF_PASSWORD') }
  let(:app_name) { "guarddog-#{SecureRandom.uuid}" }
  let(:cf_home) { Dir.mktmpdir }
  let(:org) { app_name }
  let(:space) { app_name }

  before(:each) do
    ENV['CF_HOME'] = cf_home
    `cf`
    expect($?.success?).to be_truthy, 'CF CLI should be available'
    expect(`cf buildpacks`).to_not include('guarddog'), 'Buildpack should not exist before test'
  end

  after(:each) do
    `cf delete -f #{app_name}` rescue nil
    File.delete(filename) rescue nil
    FileUtils.rm_rf(cf_home)
  end

  context 'when the buildpack is packaged', :if => ENV.fetch("CREATE_BUILDPACK") == "true"  do
    after(:each) do
       `cf delete-buildpack -f guarddog` rescue nil
       `cf delete-org -f #{org}` rescue nil
    end

    it 'runs apps with haproxy' do
      expect_command_to_succeed("buildpack-packager --cached --use-custom-manifest spec/integration/fixtures/buildpack-manifest.yml")
      expect(File).to exist(filename)

      expect_command_to_succeed("cf api #{cf_api} --skip-ssl-validation")
      expect_command_to_succeed_and_output("cf auth #{cf_username} #{cf_password}", "Authenticating...\nOK")
      expect_command_to_succeed("cf create-buildpack guarddog #{filename} 999 --enable")

      expect_command_to_succeed_and_output("cf create-org #{org}", 'OK')
      expect_command_to_succeed("cf target -o #{org}")
      expect_command_to_succeed_and_output("cf create-space #{space}", 'OK')
      expect_command_to_succeed("cf target -s #{space}")

      expect_command_to_succeed("cf push #{app_name} -p spec/integration/fixtures/caddy-app")

      expect_command_to_succeed_and_output("cf ssh #{app_name} --command \"ls -la app/\"", 'haproxy')
      expect_hap_to_require_basic_auth
      expect_200_on_valid_auth
    end
  end

  context 'when the buildpack is specified by URI', :if => ENV.fetch("CREATE_BUILDPACK") == "false" do
    let(:org) { ENV.fetch('CF_ORG') }
    let(:space) { ENV.fetch('CF_SPACE') }
    let(:git_branch) { ENV.fetch('GIT_BRANCH') }
    let(:guarddog_buildpack_uri) { "#{ENV.fetch('GD_BUILDPACK_URI')}##{git_branch}" }

    it 'runs apps with haproxy' do
      expect_command_to_succeed_and_output("cf api #{cf_api} --skip-ssl-validation", "OK")
      expect_command_to_succeed_and_output("cf auth #{cf_username} #{cf_password}", "Authenticating...\nOK")

      expect_command_to_succeed("cf target -o #{org}")
      expect_command_to_succeed("cf target -s #{space}")
      expect_command_to_succeed("cf push #{app_name} -p spec/integration/fixtures/caddy-app -b #{guarddog_buildpack_uri}")

      app_info = `cf curl /v2/apps/$(cf app #{app_name} --guid)`
      if app_info.include? '"diego": true'
        expect_command_to_succeed_and_output("cf ssh #{app_name} --command \"ls -la app/\"", 'haproxy')
      else
        expect_command_to_succeed_and_output("cf files #{app_name} app/", 'haproxy')
      end

      expect_hap_to_require_basic_auth
      expect_200_on_valid_auth
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
end
