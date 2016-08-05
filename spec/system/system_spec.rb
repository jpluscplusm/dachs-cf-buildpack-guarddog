require 'fileutils'
require 'securerandom'
require 'tmpdir'

describe 'using the buildpack on a public CF' do
  let(:cf_api) { ENV.fetch('CF_API') }
  let(:cf_username) { ENV.fetch('CF_USERNAME') }
  let(:cf_password) { ENV.fetch('CF_PASSWORD') }
  let(:org) { ENV.fetch('CF_ORG') }
  let(:space) { ENV.fetch('CF_SPACE') }
  let(:app_name) { "guarddog-test-app-#{SecureRandom.uuid}" }
  let(:buildpack_uri) { ENV.fetch('BUILDPACK_URI') }
  let(:cf_home) { Dir.tmpdir }

  before(:each) do
    ENV['CF_HOME'] = cf_home
  end

  after(:each) do
    `cf delete -f #{app_name}`
    FileUtils.rm_rf cf_home
  end

  it 'can be used to start trivial apps' do
    `cf login -a #{cf_api} -u #{cf_username} -p #{cf_password} -o #{org} -s #{space} --skip-ssl-validation`
    expect($?.success?).to be_truthy, 'Login should have worked'

    push_success = system("cf push #{app_name} -p spec/system/fixtures/app -b #{buildpack_uri} --no-route")
    expect(push_success).to be_truthy

    expect(`cf app #{app_name}`).to include("buildpack: #{buildpack_uri}")
  end
end