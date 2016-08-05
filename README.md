# dachs-cf-buildpack-guarddog
A Cloud Foundry buildpack which protects and instruments applications

## Testing

### Pre-requisites

* Ruby (look in Gemfile for version)
* Bundler
* `zip`

Alternatively use the [cf-bosh-cli](https://github.com/Orange-OpenSource/orange-cf-bosh-cli) Docker images.

```
$ bundle exec rake:unit
$ bundle exec rake:integration
```