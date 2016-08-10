# dachs-cf-buildpack-guarddog

A Cloud Foundry buildpack which protects and instruments applications

## Testing

### Pre-requisites

* Ruby (look in Gemfile for version)
* Bundler

### Local

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
  bundle exec rake spec:integration
```

### System

Requires that the buildpack we want to test is available via a Git URI.

```
$ CF_API=https://api.bosh-lite.com \
  CF_USERNAME=admin \
  CF_PASSWORD=admin \
  CF_ORG=test \
  CF_SPACE=test \
  BUILDPACK_URI=https://github.com/DigitalInnovation/dachs-cf-buildpack-guarddog.git \
  bundle exec rake spec:system
```
