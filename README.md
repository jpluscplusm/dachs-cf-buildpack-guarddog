# dachs-cf-buildpack-guarddog
A Cloud Foundry buildpack which protects and instruments applications

## Testing

### Pre-requisites

* Ruby (look in Gemfile for version)
* Bundler
* `zip`

Alternatively use the [cf-bosh-cli](https://github.com/Orange-OpenSource/orange-cf-bosh-cli) Docker images.

### Local

```
$ bundle exec rake:unit
```

### Integration

```
$ CF_API=https://api.bosh-lite.com \
  CF_USERNAME=admin \
  CF_PASSWORD=admin \
  bundle exec rake:integration
```