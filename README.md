# dachs-cf-buildpack-guarddog

A Cloud Foundry buildpack which protects and instruments applications

## CI

To set up the pipeline on a local Concourse, assuming you have a PCF Dev running locally and your SSH in `~/.ssh/id_rsa`.

```
$ fly --t lite login  --concourse-url http://192.168.100.4:8080
```

```
$ fly -t lite set-pipeline \
  --pipeline guarddog \
  --config ci/pipelines/guarddog.yml \
  --var "private-repo-key=$(cat ~/.ssh/id_rsa)"
  --load-vars-from ci/vars/pcfdev.yml
```

The SSH key is used for pushing to the `acceptance` branch, so you probably don't want to do this unless you're working on the pipeline itself.

## Testing

### Pre-requisites

* [Ruby][Ruby] (look in Gemfile for version)
* [Bundler][Bundler] (`gem install bundler`)

### Local

```
$ bundle install
```

```
$ bundle exec rake spec:unit
```

### Integration

Requires

* `zip` on `$PATH`
* a CF that we can push buildpack zips into
* CF and Bosh CLIs on `$PATH`

Alternatively use the [cf-bosh-cli](https://github.com/Orange-OpenSource/orange-cf-bosh-cli) Docker image, which has all the binary dependencies.

```
$ CF_API=https://api.bosh-lite.com \
  CF_USERNAME=admin \
  CF_PASSWORD=admin \
  ci/unit-test/run.sh
```

### System

Requires that the buildpack we want to test is available via a Git URI.

```
$ CF_API=https://api.local.pcfdev.io \
  APP_DOMAIN=local.pfcdev.io
  CF_USERNAME=admin \
  CF_PASSWORD=admin \
  CF_ORG=test \
  CF_SPACE=test \
  MULTI_BUILDPACK_URI=https://github.com/DigitalInnovation/dachs-cf-buildpack-multi.git#branch \
  GD_BUILDPACK_URI=https://github.com/DigitalInnovation/dachs-cf-buildpack-guarddog.git#branch \
  ci/system-test/run.sh
```

[Ruby]: https://www.ruby-lang.org/en/
[Bundler]: https://bundler.io/
