defmodule Farmbot.CeleryScript.AST.Node.ConfigUpdate do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  use Farmbot.Logger
  allow_args [:package]

  def execute(%{package: :farmbot_os}, _body, env) do
    Logger.warn 2, "`config_update` for FBOS is depricated."
    env = mutate_env(env)
    {:ok, env}
  end

  def execute(%{package: :arduino_firmware}, body, env) do
    env = mutate_env(env)
    do_reduce_fw(body, env)
  end

  defp do_reduce_fw([%{args: %{label: key, value: value}} | rest], env) do
    case Farmbot.Firmware.update_param(:"#{key}", value) do
      :ok -> do_reduce_fw(rest, env)
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp do_reduce_fw([], env), do: {:ok, env}
end
