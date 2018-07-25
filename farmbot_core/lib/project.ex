defmodule Farmbot.Project do
  @moduledoc "Farmbot project config"

  @version Mix.Project.config[:version] || Mix.raise("Something broke")
  @target Mix.Project.config[:target] || Mix.raise("Something broke")
  @commit Mix.Project.config[:commit] || Mix.raise("Something broke")
  @arduino_commit Mix.Project.config[:arduino_commit] || Mix.raise("Something broke")
  @env Mix.env()

  @doc "*#{@version}*"
  @compile {:inline, version: 0}
  def version, do: @version

  @doc "*#{@commit}*"
  @compile {:inline, commit: 0}
  def commit, do: @commit

  @doc "*#{@arduino_commit}*"
  @compile {:inline, arduino_commit: 0}
  def arduino_commit, do: @arduino_commit

  @doc "*#{@target}*"
  @compile {:inline, target: 0}
  def target, do: @target

  @doc "*#{@env}*"
  @compile {:inline, env: 0}
  def env, do: @env
end
