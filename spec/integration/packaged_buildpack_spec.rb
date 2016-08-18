require 'fileutils'
require 'securerandom'
require 'tmpdir'

describe 'GuardDog buildpack alone' do
  let(:version) { File.open('VERSION').read }
  let(:filename) { "guarddog_buildpack-cached-v#{version}.zip" }
  let(:cf_api) { ENV.fetch('CF_API') }
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

    it 'can be created' do
      expect_command_to_succeed("buildpack-packager --cached --use-custom-manifest spec/integration/fixtures/buildpack-manifest.yml")
      expect(File).to exist(filename)

      expect_command_to_succeed("cf api #{cf_api} --skip-ssl-validation")
      expect_command_to_succeed_and_output("cf auth #{cf_username} #{cf_password}", "Authenticating...\nOK")
      expect_command_to_succeed("cf create-buildpack guarddog #{filename} 999 --enable")

      expect_command_to_succeed_and_output("cf create-org #{org}", 'OK')
      expect_command_to_succeed("cf target -o #{org}")
      expect_command_to_succeed_and_output("cf create-space #{space}", 'OK')
      expect_command_to_succeed("cf target -s #{space}")

      expect_command_to_succeed("cf push #{app_name} -p spec/integration/fixtures/app --no-start")
      expect_command_to_succeed("cf set-health-check #{app_name} none")
      expect_command_to_succeed("cf start #{app_name}")

      expect_command_to_succeed_and_output("cf ssh #{app_name} --command \"ls -la app/\"", '.guarddog')
    end
  end

  context 'when the buildpack is specified by URI', :if => ENV.fetch("CREATE_BUILDPACK") == "false" do
    let(:org) { ENV.fetch('CF_ORG') }
    let(:space) { ENV.fetch('CF_SPACE') }
    let(:guarddog_buildpack_uri) { ENV.fetch('GD_BUILDPACK_URI') }

    it 'can be used' do
      expect_command_to_succeed_and_output("cf api #{cf_api} --skip-ssl-validation", "OK")
      expect_command_to_succeed_and_output("cf auth #{cf_username} #{cf_password}", "Authenticating...\nOK")

      expect_command_to_succeed("cf target -o #{org}")
      expect_command_to_succeed("cf target -s #{space}")
      expect_command_to_succeed("cf push #{app_name} -p spec/integration/fixtures/app -b #{guarddog_buildpack_uri} --no-start --no-route")

      app_info = `cf curl /v2/apps/$(cf app #{app_name} --guid)`
      if app_info.include? '"diego": true'
        expect_command_to_succeed("cf set-health-check #{app_name} none")
        expect_command_to_succeed("cf start #{app_name}")
        expect_command_to_succeed_and_output("cf ssh #{app_name} --command \"ls -la app/\"", '.guarddog')
      else
        expect_command_to_succeed("cf start #{app_name}")
        expect_command_to_succeed_and_output("cf files #{app_name} app/", '.guarddog')
      end
    end
  end

  def expect_command_to_succeed(command)
    system(command)
    expect($?.success?).to be_truthy
  end

  def expect_command_to_succeed_and_output(command, expected)
    output = `#{command}`
    expect($?.success?).to be_truthy
    expect(output).to include(expected)
  end
end
