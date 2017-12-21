defmodule Farmbot.Project do
  @moduledoc "Farmbot project config"

  @version Mix.Project.config[:version]
  @target Mix.Project.config[:target]
  @commit Mix.Project.config[:commit]
  @env Mix.env()

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
