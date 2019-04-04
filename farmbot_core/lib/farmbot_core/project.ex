defmodule FarmbotCore.Project do
  @moduledoc "Farmbot project config"

  @version Mix.Project.config[:version] || Mix.raise("Missing Project key version")
  @commit Mix.Project.config[:commit] || Mix.raise("Missing Project key commit")
  @branch Mix.Project.config[:branch] || Mix.raise("Missing Project key branch")

  @target Mix.target()
  @env Mix.env()
  @target Mix.target()

  @external_resource ".git"

  @doc "*#{@version}*"
  @compile {:inline, version: 0}
  def version, do: @version

  @doc "*#{@commit}*"
  @compile {:inline, commit: 0}
  def commit, do: @commit

  @doc "*#{@branch}*"
  @compile {:inline, branch: 0}
  def branch, do: @branch

  def arduino_commit,  do: FarmbotFirmware.Project.arduino_commit()

  @doc "*#{@target}*"
  @compile {:inline, target: 0}
  def target, do: @target

  @doc "*#{@env}*"
  @compile {:inline, env: 0}
  def env, do: @env
end
