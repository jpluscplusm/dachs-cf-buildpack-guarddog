require 'yaml'

class MininitMaker

  FORCED_PORT = 3000

  def initialize(app_release)
    @app_release = app_release
  end

  def create
    mininit = File.new("mininit.sh", "wb")

    contents = <<-EOF
#!/bin/bash

set -e

#{app_command} &

while ! nc -z localhost #{FORCED_PORT}; do
  sleep 0.2
done

#{hap_command}
EOF
    mininit.puts(contents)
    mininit.close
  end

private
  attr_reader :app_release

  def app_command
    yaml = YAML.load_file(app_release)

    config_vars = parse_config(yaml["config_vars"])
    raw_command = parse_command(yaml["default_process_types"])
    command = raw_command.gsub(/\$PORT/, "#{FORCED_PORT}")
    
    "PORT=#{FORCED_PORT} #{config_vars}#{command}"
  end

  def parse_config(vars)
    return "" if vars.nil?
    vars.map do |k, v|
      "#{k}=#{v}"
    end.compact.join(" ") + " "
  end

  def parse_command(commands)
    commands["web"]
  end

  def hap_command
    "./haproxy -f haproxy.cfg"
  end
end