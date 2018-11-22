defmodule Farmbot.CeleryScript.AST.Node.CheckUpdates do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:package]

  def execute(%{package: :farmbot_os}, _, env) do
    env = mutate_env(env)
    case legacy_updater(env) do
      {:error, _reasson, env} -> nerves_hub_updater(env)
      {:ok, env} -> {:ok, env}
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

  defp legacy_updater(env) do
    case Farmbot.System.Updates.check_updates() do
      {:error, reason} -> {:error, reason, env}
      nil -> {:ok, env}
      {%Version{} = version, url} ->
        case Farmbot.System.Updates.download_and_apply_update({version, url}) do
          :ok -> {:ok, env}
          {:error, reason} -> {:error, reason, env}
        end
    end
  end

  defp nerves_hub_updater(env) do
    case Farmbot.System.NervesHub.check_update() do
      nil -> {:ok, env}
      url when is_binary(url) -> {:ok, env}
    end
  end
end
