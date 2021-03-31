defmodule ExCoveralls.Task.Util do
  @moduledoc """
  Provides task related utilities.
  """

  def print_help_message do
    IO.puts """
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

Usage: mix coveralls.html
  Used to display coverage information at the source-code level formatted as an HTML page.

Usage: mix coveralls.travis [--pro]
  Used to post coverage from Travis CI server.

Usage: mix coveralls.github
  Used to post coverage from a GitHub Action.

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
"""
  end
end
