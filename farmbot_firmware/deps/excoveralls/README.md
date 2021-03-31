ExCoveralls
============

[![Build Status](https://github.com/parroty/excoveralls/workflows/tests/badge.svg)](https://github.com/parroty/excoveralls/actions)
[![Coverage Status](https://coveralls.io/repos/parroty/excoveralls/badge.svg?branch=master)](https://coveralls.io/r/parroty/excoveralls?branch=master)
[![hex.pm version](https://img.shields.io/hexpm/v/excoveralls.svg)](https://hex.pm/packages/excoveralls)
[![hex.pm downloads](https://img.shields.io/hexpm/dt/excoveralls.svg)](https://hex.pm/packages/excoveralls)
[![hex.pm license](https://img.shields.io/hexpm/l/excoveralls.svg)](https://github.com/yyy/excoveralls/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/parroty/excoveralls.svg)](https://github.com/parroty/excoveralls/commits/master)

An Elixir library that reports test coverage statistics, with the option to post to [coveralls.io](https://coveralls.io/) service.
It uses Erlang's [cover](http://www.erlang.org/doc/man/cover.html) to generate coverage information, and posts the test coverage results to coveralls.io through the JSON API.

The following are example projects.
  - [coverage_sample](https://github.com/parroty/coverage_sample) is for Travis CI.
  - [github_coverage_sample](https://github.com/mijailr/actions_sample) is for GitHub Actions.
  - [circle_sample](https://github.com/parroty/circle_sample) is for CircleCI .
  - [semaphore_sample](https://github.com/parroty/semaphore_sample) is for Semaphore CI.
  - [excoveralls_umbrella](https://github.com/parroty/excoveralls_umbrella) is for umbrella project.
  - [gitlab_sample](https://gitlab.com/parroty/gitlab_sample) is for GitLab CI (using GitLab CI feature instead of coveralls.io).
  - [gitlab_parallel_sample](https://gitlab.com/parroty/excoveralls-demo) is for GitLab CI (with parallel option).
  - [drone_sample](https://github.com/vorce/drone_sample) is for Drone CI.

# Settings
### mix.exs
Add the following parameters.

- `test_coverage: [tool: ExCoveralls]` for using ExCoveralls for coverage reporting.
- `preferred_cli_env: [coveralls: :test]` for running `mix coveralls` in `:test` env by default
    - It's an optional setting for skipping `MIX_ENV=test` part when executing `mix coveralls` tasks.
- `test_coverage: [test_task: "espec"]` if you use Espec instead of default ExUnit.
- `:excoveralls` in the deps function.

```elixir
def project do
  [
    app: :excoveralls,
    version: "1.0.0",
    elixir: "~> 1.0.0",
    deps: deps(),
    test_coverage: [tool: ExCoveralls],
    preferred_cli_env: [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
    # if you want to use espec,
    # test_coverage: [tool: ExCoveralls, test_task: "espec"]
  ]
end

defp deps do
  [
    {:excoveralls, "~> 0.10", only: :test},
  ]
end
```

**Note on umbrella application**: If you want to use Excoveralls within an umbrella project, every `apps` must have
`test_coverage: [tool: ExCoveralls]` in the `mix.exs` of each app.

**Note:** If you're using earlier than `elixir v1.3`, `MIX_ENV=test` or `preferred_cli_env` may be required for running mix tasks. Refer to [PR#96](https://github.com/parroty/excoveralls/pull/96) for the details.

# Usage
## Mix Tasks
- [Settings](#settings)
    - [mix.exs](#mixexs)
- [Usage](#usage)
  - [Mix Tasks](#mix-tasks)
    - [[mix coveralls] Show coverage](#mix-coveralls-show-coverage)
    - [[mix coveralls.travis] Post coverage from travis](#mix-coverallstravis-post-coverage-from-travis)
      - [.travis.yml](#travisyml)
    - [[mix coveralls.github] Post coverage from GitHub Actions](#mix-coverallsgithub-post-coverage-from-github-actions)
      - [.github/workflows/main.yml](#githubworkflowsexampleyml)
    - [[mix coveralls.circle] Post coverage from circle](#mix-coverallscircle-post-coverage-from-circle)
      - [circle.yml](#circleyml)
    - [[mix coveralls.semaphore] Post coverage from semaphore](#mix-coverallssemaphore-post-coverage-from-semaphore)
      - [semaphore build instructions](#semaphore-build-instructions)
    - [[mix coveralls.drone] Post coverage from drone](#mix-coverallsdrone-post-coverage-from-drone)
      - [.drone.yml](#droneyml)
    - [[mix coveralls.post] Post coverage from any host](#mix-coverallspost-post-coverage-from-any-host)
    - [[mix coveralls.detail] Show coverage with detail](#mix-coverallsdetail-show-coverage-with-detail)
    - [[mix coveralls.html] Show coverage as HTML report](#mix-coverallshtml-show-coverage-as-html-report)
    - [[mix coveralls.json] Show coverage as JSON report](#mix-coverallsjson-show-coverage-as-json-report)
    - [[mix coveralls.xml] Show coverage as XML report](#mix-coverallsxml-show-coverage-as-xml-report)
  - [coveralls.json](#coverallsjson)
      - [Stop Words](#stop-words)
      - [Exclude Files](#exclude-files)
      - [Terminal Report Output](#terminal-report-output)
      - [Coverage Options](#coverage-options)
  - [Ignore Lines](#ignore-lines)
  - [Notes](#notes)
  - [Todo](#todo)

### [mix coveralls] Show coverage
Run the `MIX_ENV=test mix coveralls` command to show coverage information on localhost.
This task locally prints out the coverage information. It doesn't submit the results to the server.

```Shell
$ MIX_ENV=test mix coveralls
...
----------------
COV    FILE                                        LINES RELEVANT   MISSED
100.0% lib/excoveralls/general.ex                     28        4        0
 75.0% lib/excoveralls.ex                             54        8        2
 94.7% lib/excoveralls/stats.ex                       70       19        1
100.0% lib/excoveralls/poster.ex                      16        3        0
 95.5% lib/excoveralls/local.ex                       79       22        1
100.0% lib/excoveralls/travis.ex                      23        3        0
100.0% lib/mix/tasks.ex                               44        8        0
100.0% lib/excoveralls/cover.ex                       32        5        0
[TOTAL]  94.4%
----------------
```

Specifying the `--help` option displays the options list for available tasks.

```Shell
Usage: mix coveralls <Options>
  Used to display coverage

  <Options>
    -h (--help)         Show helps for excoveralls mix tasks

    Common options across coveralls mix tasks

    -o (--output-dir)   Write coverage information to output dir.
    -u (--umbrella)     Show overall coverage for umbrella project.
    -v (--verbose)      Show json string for posting.

Usage: mix coveralls.detail [--filter file-name-pattern]
  Used to display coverage with detail
  [--filter file-name-pattern] can be used to limit the files to be displayed in detail.

Usage: mix coveralls.travis [--pro]
  Used to post coverage from Travis CI server.

Usage: mix coveralls.github
  Used to post coverage from [GitHub Actions](https://github.com/features/actions).

Usage: mix coveralls.post <Options>
  Used to post coverage from local server using token.
  The token should be specified in the argument or in COVERALLS_REPO_TOKEN
  environment variable.

  <Options>
    -t (--token)        Repository token ('REPO TOKEN' of coveralls.io)
    -n (--name)         Service name ('VIA' column at coveralls.io page)
    -b (--branch)       Branch name ('BRANCH' column at coveralls.io page)
    -c (--committer)    Committer name ('COMMITTER' column at coveralls.io page)
    -m (--message)      Commit message ('COMMIT' column at coveralls.io page)
    -s (--sha)          Commit SHA (required when not using Travis)
```

### [mix coveralls.travis] Post coverage from travis
Specify `mix coveralls.travis` as the build script in the `.travis.yml` and explicitly set the `MIX_ENV` environment to `TEST`.
This task submits the result to Coveralls when the build is executed on Travis CI.

#### .travis.yml
```yml
language: elixir

elixir:
  - 1.2.0

otp_release:
  - 18.0

env:
  - MIX_ENV=test

script: mix coveralls.travis
```

If you're using [Travis Pro](https://travis-ci.com/) for a private
project, Use `coveralls.travis --pro` and ensure your coveralls.io
repo token is available via the `COVERALLS_REPO_TOKEN` environment
variable.

### [mix coveralls.github] Post coverage from [GitHub Actions](https://github.com/features/actions)
Specify `mix coveralls.github` as the build script in the GitHub action YML file and explicitly set the `MIX_ENV` environment to `test` and add `GITHUB_TOKEN` with the value of `{{ secrets.GITHUB_TOKEN }}`, this is required because is used internally by coveralls.io to check the action and add statuses.

The value of `secrets.GITHUB_TOKEN` is added automatically inside every GitHub action, so you not need to assign that.

This task submits the result to Coveralls when the build is executed via GitHub actions and add statuses in the checks of github.

#### .github/workflows/example.yml
```yml
on: push

jobs:
  test:
    runs-on: ubuntu-latest
    name: OTP ${{matrix.otp}} / Elixir ${{matrix.elixir}}
    strategy:
      matrix:
        otp: [21.3.8.10, 22.1.7]
        elixir: [1.8.2, 1.9.4]
    env:
      MIX_ENV: test
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@v1.0.0
      - uses: actions/setup-elixir@v1.0.0
        with:
          otp-version: ${{matrix.otp}}
          elixir-version: ${{matrix.elixir}}
      - run: mix deps.get
      - run: mix coveralls.github
```

### [mix coveralls.circle] Post coverage from circle
Specify `mix coveralls.circle` in the `circle.yml`.
This task is for submitting the result to the coveralls server when Circle-CI build is executed.

#### circle.yml
```yml
test:
  override:
    - mix coveralls.circle
```

Ensure your coveralls.io repo token is available via the `COVERALLS_REPO_TOKEN` environment
variable.

### [mix coveralls.semaphore] Post coverage from semaphore
Specify `mix coveralls.semaphore` in the build command prompt for instructions in semaphore.
This task is for submitting the result to the coveralls server when Semaphore-CI build is executed.

#### semaphore build instructions
```
mix coveralls.semaphore
```

Ensure your coveralls.io repo token is available via the `COVERALLS_REPO_TOKEN` environment
variable.

### [mix coveralls.drone] Post coverage from drone
Specify `mix coveralls.drone` in the `.drone.yml`.
This task is for submitting the result to the coveralls server when the Drone build is executed.

You will also need to add your coveralls repo token as a secret to the drone project:
`drone secret add --repository=your-namespace/your-project --name=coveralls_repo_token --value=xyz`

#### .drone.yml

```yml
pipeline:
  build:
    secrets: [ coveralls_repo_token ]
    commands:
      - mix coveralls.drone
```

### [mix coveralls.post] Post coverage from any host
Acquire the repository token of coveralls.io in advance, and run the `mix coveralls.post` command.
It is for submitting the result to coveralls server from any host.

The token can be specified as a mix task option (`--token`), or as an environment variable (`COVERALLS_REPO_TOKEN`).

```Shell
MIX_ENV=test mix coveralls.post --token [YOUR_TOKEN] --branch "master" --name "local host" --committer "committer name" --sha "fd80a4c" --message "commit message"
....................................................................................................

Finished in 6.3 seconds (0.7s on load, 5.6s on tests)
100 tests, 0 failures

Randomized with seed 800810
Successfully uploaded the report to 'https://coveralls.io'.
```
For the detailed option description, check [mix coveralls --help](#mix-coveralls-show-coverage) task.

### [mix coveralls.detail] Show coverage with detail
This task displays coverage information at the source-code level with colored text.
Green indicates a tested line, and red indicates lines which are not tested.
When reviewing many source files, pipe the output to the `less` program (with the `-R` option for color) to paginate the results.

```Shell
$ MIX_ENV=test mix coveralls.detail | less -R
...
----------------
COV    FILE                                        LINES RELEVANT   MISSED
100.0% lib/excoveralls/general.ex                     28        4        0
...
[TOTAL]  94.4%

--------lib/excoveralls.ex--------
defmodule ExCoveralls do
  @moduledoc """
  Provides the entry point for coverage calculation and output.
  This module method is called by Mix.Tasks.Test
...
```

Also, displayed source code can be filtered by specifying arguments (it will be matched against the FILE column value). The following example lists the source code only for general.ex.
```Shell
$ MIX_ENV=test mix coveralls.detail --filter general.ex
...
----------------
COV    FILE                                        LINES RELEVANT   MISSED
100.0% lib/excoveralls/general.ex                     28        4        0
...
[TOTAL]  94.4%

--------lib/excoveralls.ex--------
defmodule ExCoveralls do
  @moduledoc """
  Provides the entry point for coverage calculation and output.
  This module method is called by Mix.Tasks.Test
...
```

### [mix coveralls.html] Show coverage as HTML report
This task displays coverage information at the source-code level formatted as an HTML page.
The report follows the format inspired by HTMLCov from the Mocha testing library in JS.
Output to the shell is the same as running the command `mix coveralls` (to suppress this output, add `"print_summary": false` to your project's `coveralls.json` file). In a similar manner to `mix coveralls.detail`, reported source code can be filtered by specifying arguments using the `--filter` flag.

```Shell
$ MIX_ENV=test mix coveralls.html
```
![HTML Report](./assets/html_report.jpg?raw=true "HTML Report")

Output reports are written to `cover/excoveralls.html` by default, however, the path can be specified by overwriting the `"output_dir"` coverage option.
Custom reports can be created and utilized by defining `template_path` in `coveralls.json`. This directory should
contain an eex template named `coverage.html.eex`.

### [mix coveralls.json] Show coverage as JSON report
This task displays coverage information at the source-code level formatted as a JSON document.
The report follows a format supported by several code coverage services, including Codecov and Code Climate.
Output to the shell is the same as running the command `mix coveralls` (to suppress this output, add `"print_summary": false` to your project's `coveralls.json` file). In a similar manner to `mix coveralls.detail`, reported source code can be filtered by specifying arguments using the `--filter` flag.

Upload a coverage report to Codecov using their [bash uploader](https://docs.codecov.io/docs/about-the-codecov-bash-uploader)
or to Code Climate using their [test-reporter](https://docs.codeclimate.com/docs/configuring-test-coverage).

Output reports are written to `cover/excoveralls.json` by default, however, the path can be specified by overwriting the `"output_dir"` coverage option.

### [mix coveralls.xml] Show coverage as XML report
This task displays coverage information at the source-code level formatted as a XML document.
The report follows a format supported by several code coverage services like SonarQube.
Output to the shell is the same as running the command `mix coveralls` (to suppress this output, add `"print_summary": false` to your project's `coveralls.json` file). In a similar manner to `mix coveralls.detail`, reported source code can be filtered by specifying arguments using the `--filter` flag.

Output reports are written to `cover/excoveralls.xml` by default, however, the path can be specified by overwriting the `"output_dir"` coverage option.

## coveralls.json
`coveralls.json` provides settings for excoveralls.

The default `coveralls.json` file is stored in `deps/excoveralls/lib/conf`, and custom `coveralls.json` files can be placed in the mix project root. The custom definition is prioritized over the default one (if definitions in the custom file are not found, then the definitions in the default file are used).

#### Stop Words
Stop words defined in `coveralls.json` will be excluded from the coverage calculation. Some kernel macros defined in Elixir are not considered "covered" by Erlang's cover library. It can be used for excluding these macros, or for any other reasons. The words are parsed as regular expression.

#### Exclude Files

If you want to exclude/ignore files from the coverage calculation add the `skip_files` key in the `coveralls.json` file. `skip_files` takes an array of file paths, for example:

```javascript
{
  "skip_files": [
    "folder_to_skip",
    "folder/file_to_skip.ex"
  ]
}
```

Path should contain a string that can be compiled to Elixir regex, you can test them running `Regex.compile("your_path")` in your `iex` shell.

Note that this doesn't work directly in an umbrella project. If you need to exclude files within an app, you should create a separate `coveralls.json` at the root of the app's folder and add a `skip_files` key to _that_ file. Paths should be relative to that file, not the umbrella project.

#### Terminal Report Output
When using in umbrella projects the default report may trim files names when viewing report in terminal.

If you want to change the column width used for file names add the `file_column_width` key to the `terminal_options` key in the `coveralls.json`, for example:

```javascript
{
  "terminal_options": {
    "file_column_width": 40
  }
}
```

If you want to see only the total coverage without a table of each file, set the `print_files` option
to `false`:

```javascript
{
  "terminal_options": {
    "print_files": false
  }
}
```

#### Coverage Options
- `treat_no_relevant_lines_as_covered`
  - By default, coverage for [files with no relevant lines] are displayed as 0% for aligning with coveralls.io behavior. But, if `treat_no_relevant_lines_as_covered` is set to `true`, it will be displayed as 100%.
- `output_dir`
  - The directory which the HTML report will output to. Defaulted to `cover/`.
- `template_path`
  - A custom path for html reports. This defaults to the htmlcov report in the excoveralls lib.
- `minimum_coverage`
  - When set to a number greater than 0, this setting causes the `mix coveralls` and `mix coveralls.html` tasks to exit with a status code of 1 if test coverage falls below the specified threshold (defaults to 0). This is useful to interrupt CI pipelines with strict code coverage rules. Should be expressed as a number between 0 and 100 signifying the minimum percentage of lines covered.

Example configuration file:

```javascript
{
  "default_stop_words": [
    "defmodule",
    "defrecord",
    "defimpl",
    "def.+(.+\/\/.+).+do"
  ],

  "custom_stop_words": [
  ],

  "coverage_options": {
    "treat_no_relevant_lines_as_covered": true,
    "output_dir": "cover/",
    "template_path": "custom/path/to/template/",
    "minimum_coverage": 90,
    "xml_base_dir": "custom/path/for/xml/reports/"
  }
}
```

### Ignore Lines

Use comments `coveralls-ignore-start` and `coveralls-ignore-stop` to ignore certain lines from code coverage calculation.

```elixir
defmodule MyModule do
  def covered do
  end

  # coveralls-ignore-start
  def ignored do
  end
  # coveralls-ignore-stop
end
```

### Notes
- If mock library is used, it will show some warnings during execution.
    - https://github.com/eproxus/meck/pull/17
- In case Erlang clashes at `mix coveralls`, executing `mix test` in advance might avoid the error.
- When erlang version 17.3 is used, an error message `(MatchError) no match of right hand side value: ""` can be shown. Refer to issue #14 for the details.
    - https://github.com/parroty/excoveralls/issues/14

### Todo
- It might not work well on projects which handle multiple project (Mix.Project) files.
    - Needs improvement on file-path handling.

## License

This source code is licensed under the MIT license. Copyright (c) 2013-present, parroty.
