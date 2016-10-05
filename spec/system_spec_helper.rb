def write_buildpacks_file(fixture_dir, buildpack_url)
  File.open(multi_buildpack_conf_path, 'w') { |file|
    file.puts buildpack_url
    file.puts guarddog_buildpack_uri
    file.puts ps_buildpack_uri
  }
end

def push_and_check_if_diego?
  expect_command_to_succeed("cf push #{app_name} -p #{app_path} -b #{multi_buildpack_uri} --no-start")
  expect_command_to_succeed("cf set-env #{app_name} FBP_RP_USER_dev nottheexpectedpassword")
  expect_command_to_succeed("cf set-env #{app_name} FBP_RP_USER_foo bar")
  expect_command_to_succeed("cf set-env #{app_name} FBP_RP_ACTIVE_USERNAMES 'dev,foo'")
  is_diego?
end

def is_diego?
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

def expect_app_returns_with_dev_password(code, password)
  if code < 400
    response = RestClient::Request.execute(method: :get, url: "https://#{app_name}.#{app_domain}", verify_ssl: OpenSSL::SSL::VERIFY_NONE, user: 'dev', password: password)
    expect(response.code).to be(code)
  else
    expect{RestClient::Request.execute(method: :get, url: "https://#{app_name}.#{app_domain}", verify_ssl: OpenSSL::SSL::VERIFY_NONE, user: 'dev', password: password)}.to raise_error { |error|
      expect(error.response.code).to be(code)
    }
  end
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
    threads = number.times.map { |count|
      Thread.new do
        observed = make_slow_request(0)
        expect(observed).to eq(code), "Request #{count} returned #{observed}"
      end
    }

    ThreadsWait.all_waits(*threads)
  end

  def expect_hap_termination_state(number)
    expect {
      output = `cf logs #{app_name} --recent`
      output.scan('sH--').size
      }.to eventually(eq(number)).within 90
    end