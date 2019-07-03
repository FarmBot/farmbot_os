#!/usr/bin/env elixir
{_, 0} = System.cmd("git", ["checkout", "staging"], into: IO.stream(:stdio, :line))
{_, 0} = System.cmd("git", ["fetch", "--all"], into: IO.stream(:stdio, :line))
{_, 0} = System.cmd("git", ["reset", "--hard", "origin/staging"], into: IO.stream(:stdio, :line))
version = File.read!("VERSION") |> Version.parse!()
[<<"rc", rc :: binary>>] = version.pre
version = %{version | pre: ["rc#{String.to_integer(rc) + 1}"]}
:ok = File.write!("VERSION", to_string(version))
{_, 0} = System.cmd("git", ["add", "VERSION"], into: IO.stream(:stdio, :line))
{_, 0} = System.cmd("git", ["commit", "-am", "Release v#{version}"], into: IO.stream(:stdio, :line))
{_, 0} = System.cmd("git", ["tag", "v#{version}"], into: IO.stream(:stdio, :line))
{_, 0} = System.cmd("git", ["push", "origin", "staging", "v#{version}"], into: IO.stream(:stdio, :line))