0.13.4
------
#### Enhancements
- Add `mix coveralls.gitlab` task.
   - Add a task to upload coverage from gitlab (#240).

0.13.3
------
#### Changes
- Fix warnings for elixir 1.11
    - Elixir 1.11: :eex and :tools should be listed in :extra_applications (#233).

0.13.2
------
#### Changes
- Fix issue with CircleCI parallel workflows not picking up separate builds (#228).
- Remove `text-align: right` so filenames are easier to scan (#227).

0.13.1
------
#### Changes
- Fixing mocked modules coverage handling (#226).

0.13.0
------
#### Changes
- Update hackney to fix sslv3 reference on OTP 23 (#225).
- Fix build failure due to `:connect_timeout` from poster (#221).
- Fix error reason message (#222).
    - Improve message for non-string error reason.

0.12.3
------
#### Enhancements
- Add support to generate XML files (#218).
    - Add `mix coveralls.xml` task.

0.12.2
------
#### Enhancements
- Add terminal option to hide file coverage list (#215, #148).
    - Add `print_files` flag to disable individual file outputs.

0.12.1
------
#### Enhancements
- Add support for GitHub Actions (#209).

0.12.0
------
#### Changes
- Fix for Semaphore CI 2.0 uses different CI environment variables (#179, #180).
    - It requires to use 2.0 (Breaking Change).
- Remove UndefinedFunctionError requirement for logging missing source error (#200).

0.11.2
------
#### Changes
- Update path creation/handling for artifacts (#194).

0.11.1
------
#### Enhancements
- Ignore lines between coveralls-ignore-start and coveralls-ignore-stop comments (#183).

0.11.0
------
#### Enhancements
- Add command line option for output_dir (#126, #182).
- Display path to HTML report after generation (#178).
#### Changes
- Add missing `name` switch, also fixed `committer` switch (#180).
- Fix UnicodeConversionError and faster count_line (#176).
- Fix spelling on doc for ExCoveralls.Stats.report/1 (#174).
- Relax hackney dependency (#172).

0.10.6
------
#### Changes
- Do not fail due to timeout from poster (#173).
  - Fixes: Don't fail the build when uploading the report times out (#112).

0.10.5
------
#### Changes
- Replace deprecated System.cwd/0 calls with File.cwd/0 (#170).

0.10.4
------
#### Enhancements
- Apply GZIP the JSON for coveralls and loosen the timeout (#163).

0.10.3
------
#### Changes
- Make sure analyze_sub_apps gets called (#160, #164).

0.10.2
------
#### Changes
- Argument passing for post task (#158).
    - Fixes coveralls.post doesn't recognize mix test options (#156).
- Color for case with 0 relevant lines (#159).

0.10.1
------
#### Enhancements
- Add support for drone CI (#154).
- Parallel support for separate CircleCI Workflow jobs (#155).

0.10.0
------
#### Enhancements
- Custom config file path, and ability to silence output (#153).
#### Changes
- use ~> to pin on minors & test more recent Elixirs (#152).

0.9.2
------
#### Changes
- Add meta tag for utf-8 charset to coverage.html (#144).
- Fix warnings for elixir v1.7
    - Pass switches to OptionParser.parse opts (#150).

0.9.1
------
#### Changes
- Fix umbrella stats and make source consistent (#141).

0.9.0
------
#### Enhancements
- Replace JSX with Jason (#137).

#### Changes
- Make the minimum elixir version v1.3.

0.8.2
------
#### Changes
- Ensure missing source from dirty build dir is not reported (#134).

0.8.1
------
#### Changes
- Bump meck to 0.8.9 (#129).
    - Fix for Got error while mocking a method using espec (#107).

0.8.0
------
#### Enhancements
* Add --sort option to local runner (#125).
* Merge dot file settings and project settings (#122).

0.7.5
------
#### Enhancements
* Support for ~/.excoversalls/coveralls.json (#120).

0.7.4
------
#### Changes
* Fix for Coveralls Badge only Displays Last App Tested in Umbrella App (#76).
    - Changes the behavior of mix coveralls.post so that it recognizes (#116).

0.7.3
------
#### Changes
* Fix EEx template warnings when using elixir 1.5 (#106).

0.7.2
------
#### Changes
* Fix html template is ignoring template_path from options (#105).

0.7.1
------
#### Changes
* Take the highest coverage count for a single line (#102).

0.7.0
------
#### Changes
* Do not force mix env when running tests (#101).

0.6.5
------
#### Changes
* Fix for error when using hackney 1.8.4.
  - UndefinedFunctionError after updating hackney and excoveralls the to latest version (#99).

0.6.4
------
#### Changes
* Upgrade dependencies (#98).

0.6.3
------
#### Changes
* Use `@preferred_cli_env` (#96) supported by elixir v1.3 or later.
   - Remove the `preferred_cli_env` in the `mix.exs`.

0.6.2
------
#### Changes
* Fix default handling for missing options (#86).

0.6.1
------
#### Changes
* Add optional width to column to present filename (#93).
* Update dependencies.

0.6.0
------
#### Changes
* Favor MapSet over Dict (elixir 1.2 deprecations) (#91).
   - Requires elixir v1.2 or later.
* Report 0 lines file (no relevant line) as 100.0% by default (#87).
   - If `treat_no_relevant_lines_as_covered=false` option is specified, it's reported as 0.0%.

0.5.7
------
#### Enhancements
* add json task (for Codecov.io support) (#71)
* pass through args to cover (#72)

#### Changes
* Fix --filter/-f for coveralls.detail (#79)

0.5.6
------
#### Changes
* Fix test errors with Elixir 13 (#56).
* Fix for .eex template error: no function clause matching in Enum.reverse_slice/3 (#67).
* Update dependencies.

0.5.5
------
#### Changes
* Fix Elixir 1.4 warnings (#56).

0.5.4
------
#### Enhancements
* Add Support to SemaphoreCI (#54).

0.5.3
------
#### Changes
* Make sure additional args can be passed to mix (#50).

0.5.2
------
#### Enhancements
* Add support for minimum coverage (#45).

0.5.1
------
#### Changes
* Fix umbrella source paths in report (#42).

0.5.0
------
#### Enhancements
* Add HTMLCov style reports (#40).
  - Support `mix coveralls.html` task.

0.4.6
------
#### Enhancements
* Add CircleCI integration (#39).
  - Support `mix coveralls.circle` task.

0.4.5
------
#### Changes
* Fix `mix coveralls.post` task error when passing token argument (#38).
  - Use `--token` option for specifying token.

0.4.4
------
#### Enhancements
* Support travis pro (#37).
  - Add `coveralls.travis --pro` option.

0.4.3
------
#### Enhancements
* Add --sha parameter for non-Travis compatibility (#36).

0.4.2
------
#### Changes
* Allow to override coveralls endpoint (#34).

0.4.1
------
#### Changes
* Skip a module without __info__/1 function for avoiding UndefinedFunctionError (#33).

0.4.0
------
#### Enhancements
* Add overall reporting for umbrella project (#23).
   - `mix coveralls --umbrella`
* Add `--verbose` option for printing json when posting to coveralls.io.
   - `mix coveralls.travis --verbose`
* Support specifying test runner in mix.esx (#31).
