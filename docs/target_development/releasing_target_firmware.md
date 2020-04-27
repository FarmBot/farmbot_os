# Publishing OTAs

## Beta OTA channel

Beta updates are simply tags matching the following semver string:

```
vMajor.Minor.Tiny-rcRC
```

for example:

```
v10.5.6-rc30
```

To publish an OTA, just tag a release matching that
string.

```bash
cd $FARMBOT_OS_ROOT_DIRECTORY
git checkout staging

# Ensure you don't accidentally publish local changes
# that have not gone through CI:
git fetch --all
git reset --hard origin/staging

# update the CHANGELOG, but DO NOT put the `rc`
# on the semver string.
$EDITOR CHANGELOG.md

echo 1.2.3-rc4 > VERSION

git add -A
git commit -am "Release v10.5.6-rc30"
git tag v1.2.3-rc4
git push origin v1.2.3-rc4
```

or call the helper script:
`./scripts/release_candidate.sh`

### NOTE about release candidate script

the helper script only **increments** the
RC version. Calling the `release-candidate` script
from a non rc version will fail. Example:

This will fail:

```bash
$ cat VERSION
10.5.6
./scripts/release_candidate.sh
```

This will succeed:

```bash
$ cat VERSION
10.5.6-rc44
./scripts/release_candidate.sh
```

## QA OTA channel

Publish an OTA to the `qa` channel can be done by pushing a new branch
to github with `qa/` prefix.

```bash
git checkout -b qa/<some-name>
git push origin qa/<some-name>
```

or to build a QA image from an existing branch:

```bash
git checkout -b some-feature
git commit -am "build out some feature"
git push origin some-feature some-feature:qa/some-featuer
```

## Stable OTA channel

Publish an OTA to the `stable` OTA channel can be
done by pushing anything to the master branch:

```bash
# update VERSION
echo $NEW_VERSION > VERSION
# update CHANGELOG.md
$EDITOR CHANGELOG.md
git checkout -b rel-$(cat VERSION)
git commit -am 'Release v$(cat VERSION)'
git push origin rel-$(cat VERSION)
# open pull request
# merge pull request
# publish release once CI has completed
```