## Provisioning the Release System
Publishing a FarmBotOS release requires coordination of a few different systems.
* FarmBot Web App
* FarmBot OS
* NervesHub
* CircleCI
* GitHub branches and releases

## Legacy System
The legacy system is somewhat simpiler. It goes as follows:

### Pull request into `master` branch.
```
git checkout master
git merge staging
git push origin master
```
Obviously this will not actually work because of testing and things, but that
is what happens behind the scenes on GitHub.

### CircleCI builds release
Once merged into master CircleCI will create a `draft` release on GitHub. This
must be QA'd and confirmed manually before publishing. Once published, FarmBot
will check the `OS_AUTO_UPDATE_URL` in the JWT.

### Beta updates
Users may opt into beta updates by settings `os_beta_updates: true` on their
device's `FbosConfig` endpoint.

The system works the same as production, except that the release is drafted based
on the `beta` branch. The other change is that CircleCI publishes a _real_ release
overwriting a previous release of this version if it exists. the release is tagged
as `pre_release: true` in GitHub releases. this prevents the production system
from downloading `beta` updates.

## NervesHub System
The NervesHub system is simpiler to use, but more complex to setup.

### User registration
Create a admin user. This should be the same `ADMIN_EMAIL` used in
the WebApp configuration.

```
mix nerves_hub.user register
Email address: admin@farmbot.io
Name: farmbot
NervesHub password: *super secret*
Local password: *super duper secret*
```

```
mix nerves_hub.product create
name: farmbot
Local password: *super duper secret*
```


### Signing keys
Now a choice will need to be made.

If fwup signing keys existed beforehand (they did for FarmBot Inc) do:
```
mix nerves_hub.key import <PATH/TO/PUBLIC/KEY> <PATH/TO/PRIVATE/KEY>
Local password: *super duper secret*
```

If new keys are required (probably named "prod") do:
```
mix nerves_hub.key create <NAME>
Local password: *super duper secret*
```

### Exporting certs and keys
The API and CI need copies of these keys and certs.

```
mix nerves_hub.user cert export
Local password: *super duper secret*
User certs exported to: <PATH/TO/EXPORTED_CERTS.tar.gz>
tar -xf <PATH/TO/EXPORTED_CERTS.tar.gz> -C nerves-hub/
```

```
mix nerves_hub.key export prod
Local password: *super duper secret*
Fwup keys exported to: <PATH/TO/EXPORTED_KEYS.tar.gz>
tar -xf <PATH/TO/EXPORTED_KEYS.tar.gz> -C nerves-hub/
```

You will also need the CA cert bundle for the WebApp:
(this may only work for BASH)
```bash
{ curl -s https://raw.githubusercontent.com/nerves-hub/nerves_hub_cli/master/priv/ca_certs/root-ca.pem | head -20 \
&& curl -s https://raw.githubusercontent.com/nerves-hub/nerves_hub_cli/master/priv/ca_certs/intermediate-server-ca.pem | head -20 \
  && curl -s https://raw.githubusercontent.com/nerves-hub/nerves_hub_cli/master/priv/ca_certs/intermediate-user-ca.pem | head -20;
} > nerves-hub/nerves-hub-ca-certs.pem
```

Now the FarmBot API needs the values of in it's environment:

* `NERVES_HUB_KEY` -> `cat nerves-hub/key.pem`
* `NERVES_HUB_CERT` -> `cat nerves-hub/cert.pem`
* `NERVES_HUB_CA` -> `cat nerves-hub/nerves-hub-ca-certs.pem`

CircleCI will need:

* `NERVES_HUB_KEY` -> `cat nerves-hub/key.pem`
* `NERVES_HUB_CERT` -> `cat nerves-hub/cert.pem`
* `NERVES_HUB_FW_PRIVATE_KEY` -> `cat nerves-hub/<KEY NAME>.priv`
* `NERVES_HUB_FW_PUBLIC_KEY` -> `cat nerves-hub/<KEY NAME>.pub`

### Provisioning and Tags

Tags/Deployments follow this structure:

```json
[
  "application:<MIX_ENV>",
  "channel:<CHANNEL>"
]
```

NOTE: the tags **NOT** json objects, they are simple strings
split by a `:` character. This is done _only_ for readability.

where `MIX_ENV` will be one of:
* `dev`
* `prod`

and `CHANNEL` will be one of:
* `beta`
* `stable`

There should be at least one deployment matching the following
tags:

* `["application:dev", "channel:stable"]`
    * a development FBOS release on the `stable` channel
* `["application:prod", "channel:stable"]`
    * a production FBOS release on the `stable` channel
* `["application:dev", "channel:beta"]`
    * a development FBOS release on the `beta` channel
* `["application:prod", "channel:beta"]`
    * a production FBOS release on the `beta` channel
* `["application:dev", "channel:stable"]`
    * a development FBOS release on the `stable` channel
* `["application:prod", "channel:stable"]`
    * a production FBOS release on the `stable` channel
* `["application:dev", "channel:beta"]`
    * a development FBOS release on the `beta` channel
* `["application:prod", "channel:beta"]`
    * a production FBOS release on the `beta` channel


### First time setup
```
heroku config:set NERVES_HUB_CERT="$NERVES_HUB_CERT" --app=$HEROKU_APPNAME
heroku config:set NERVES_HUB_KEY="$NERVES_HUB_KEY" --app=$HEROKU_APPNAME
heroku config:set NERVES_HUB_CA="$NERVES_HUB_CA" --app=$HEROKU_APPNAME
heroku config:set NERVES_HUB_ORG="$NERVES_HUB_ORG" --app=$HEROKU_APPNAME
```
