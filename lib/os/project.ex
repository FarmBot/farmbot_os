defmodule FarmbotOS.Project do
  @moduledoc "Farmbot project config"

  @version Mix.Project.config()[:version] ||
             Mix.raise("Missing Project key version")
  @commit Mix.Project.config()[:commit] ||
            Mix.raise("Missing Project key commit")

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

  @doc "*#{@target}*"
  @compile {:inline, target: 0}
  def target, do: @target

  @doc "*#{@env}*"
  @compile {:inline, env: 0}
  def env, do: @env
end
