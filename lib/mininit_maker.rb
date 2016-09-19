require 'yaml'

class MininitMaker

  FORCED_PORT = 3000
  RANDOM_PASSWORD = "${RANDOM}${RANDOM}${RANDOM}${RANDOM}"

  def initialize(app_release, procfile)
    @app_release = app_release
    @procfile = procfile
  end

  def create
    mininit = File.new("mininit.sh", "wb")

    contents = <<-EOF
#!/bin/bash

set -e

export TIMEOUT_SERVER=${TIMEOUT_SERVER:-60s}
export MAXCONN=${MAXCONN:-0}

#{app_command} &

while ! nc -z localhost #{FORCED_PORT}; do
  sleep 0.2
done

nc -lku 3001 &

export GD_DEV_PASSWORD=${GD_DEV_PASSWORD:-#{RANDOM_PASSWORD}}

#{hap_command} &

wait -n

echo Terminating due to a child process exiting
EOF
    mininit.puts(contents)
    mininit.close
  end

private
  attr_reader :app_release, :procfile

  def app_command
    handle_procfile unless procfile.nil?
    yaml = YAML.load_file(app_release)

    config_vars = parse_config(yaml["config_vars"])
    raw_command = parse_command(yaml["default_process_types"])
    command = raw_command.gsub(/\$PORT/, "#{FORCED_PORT}")

    "PORT=#{FORCED_PORT} #{config_vars}#{command}"
  end

  def handle_procfile
    add_process_types unless process_types_present?
    add_procfile_command
  end

  def add_process_types
    open(app_release, 'a') { |f|
      f.puts "\ndefault_process_types:"
    }
  end

  def process_types_present?
    File.readlines(app_release).grep(/.*default_process_types:.*/).any?
  end

  def add_procfile_command
    command = IO.read(procfile)
    open(app_release, 'a') { |f|
      f.puts "  #{command}"
    }
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