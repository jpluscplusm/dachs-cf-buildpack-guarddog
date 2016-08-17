# dachs-cf-buildpack-guarddog

A Cloud Foundry buildpack which protects and instruments applications

## CI

To set up the pipeline on a local Concourse, assuming you have a PCF Dev running locally and your SSH in `~/.ssh/id_rsa`.

There must be an Org called `test` containing a Space called `test` on your local PCF Dev.  If these are not set up you must run:

```
$ cf create-org test
$ cf create-space test -o test
```

```
$ fly --t lite login  --concourse-url http://192.168.100.4:8080
```

```
$ fly -t lite set-pipeline \
  --pipeline guarddog \
  --config ci/pipelines/guarddog.yml \
  --var "private-repo-key=$(cat ~/.ssh/id_rsa)" \
  --load-vars-from ci/vars/global.yml \
  --var create_buildpack=true
```

The `CREATE_BUILDPACK` var is set to true to indicate that we are running local integration tests.

The SSH key is used for pushing to the `acceptance` branch, so you probably don't want to do this unless you're working on the pipeline itself.

## Team CI

```
$ fly --t dachs login  --concourse-url https://ci.dachs.dog
```

When setting the pipeline on the team Concourse CI, we should set the `CREATE_BUILDPACK` var to "false" to run the remote integration test. You should also override the standard global vars with suitable PWS test credentials, org and space.

```
$ fly -t dachs set-pipeline \
  --pipeline guarddog \
  --config ci/pipelines/guarddog.yml \
  --var "private-repo-key=$(cat ~/.ssh/id_rsa)" \
  --load-vars-from ci/vars/global.yml \
  --var cf_username_remote = username \
  --var cf_password_remote = password \
  --var cf_space_remote = space \
  --var cf_org_remote = org \
  --var create_buildpack=false
```

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

### Integration - Before Commit

Requires

* `zip` on `$PATH`
* a CF that we can push buildpack zips into
* CF and Bosh CLIs on `$PATH`

Alternatively use the [dachs-cf-docker](https://github.com/DigitalInnovation/dachs-cf-docker) Docker image, which has all the binary dependencies and is the same image as used by the Concourse pipeline.

```
$ CREATE_BUILDPACK=true \
  CF_API=https://api.bosh-lite.com \
  CF_USERNAME=admin \
  CF_PASSWORD=admin \
  ci/integration-test/run.sh
```

### Integration - After Commit

On remote CI the changes will already have been committed and be accessible via a Git URI, and there won't be a PCF Dev available - so we don't need to bundle and install the buildpack.

```
$ CREATE_BUILDPACK=false \
  CF_API=https://api.bosh-lite.com \
  CF_USERNAME=admin \
  CF_PASSWORD=admin \
  ci/integration-test/run.sh
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
