# Publishing OTAs

## Beta

Publish an OTA to the `beta` channel can be done by:

```bash
./scripts/release_candidate.sh
```

## QA

Publish an OTA to the `qa` channel can be done by pushing a new branch
to github with `qa/` prefix.

```bash
git checkout -b qa/<some-name>
git push origin qa/<some-name>
```

## Production

Publish an OTA to the `stable` channel can be done by:

```bash
git checkout -b rel-<version>
# update VERSION
# update CHANGELOG.md
# update README.md
git commit -am "Release v<version>"
git push origin rel-<version>
# open pull request
# merge pull request
# publish release once CI has completed
```