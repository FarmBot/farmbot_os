defmodule Farmbot.CeleryScript.AST.Node.CheckUpdates do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:package]

  def execute(%{package: :farmbot_os}, _, env) do
    env = mutate_env(env)
    case Farmbot.System.Updates.check_updates() do
      {:error, reason} -> {:error, reason, env}
      nil -> {:ok, env}
      url ->
        Farmbot.System.Updates.download_and_apply_update(url)
    end
  end

  def execute(%{package: :arduino_firmware}, _, env) do
    env = mutate_env(env)
    {:error, "Arduino firmware can not be updated manually.", env}
  end

  def execute(%{package: {:farmware, _fw}} = args, _, env) do
    env = mutate_env(env)
    Farmbot.CeleryScript.AST.Node.UpdateFarmware.execute(args, [], env)
  end
end
