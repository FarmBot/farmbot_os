defmodule Farmbot.CeleryScript.AST.Node.WritePin do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  use Farmbot.Logger

  allow_args [:pin_number, :pin_value, :pin_mode]

  def execute(%{pin_mode: mode, pin_value: value, pin_number: num}, [], env) do
    env = mutate_env(env)
    case Farmbot.Firmware.write_pin(num, mode, value) do
      :ok ->
        log_success(num, mode, value)
        {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp log_success(num, :digital, 1) do
    Logger.success 1, "Pin #{num} turned on"
  end

  defp log_success(num, :digital, 0) do
    Logger.success 1, "Pin #{num} turned off"
  end

  defp log_success(num, _, val) do
    Logger.success 1, "Pin #{num}: #{val}"
  end
end
