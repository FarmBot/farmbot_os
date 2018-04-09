defmodule Farmbot.CeleryScript.AST.Node.Home do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:speed, :axis]
  use Farmbot.Logger

  def execute(%{axis: :all}, _, env) do
    env = mutate_env(env)
    maybe_log_busy()
    case Farmbot.Firmware.home_all() do
      :ok -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end

  def execute(%{axis: axis}, _, env) do
    env = mutate_env(env)
    case Farmbot.Firmware.home(axis) do
      :ok -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp maybe_log_busy do
    unless Farmbot.System.ConfigStorage.get_config_value(:bool, "settings", "firmware_input_log") do
      Logger.busy 1, "Moving to (0, 0, 0)"
    end
  end
end
