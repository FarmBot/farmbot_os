defmodule Farmbot.CeleryScript.AST.Node.ReadPin do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:pin_number, :label, :pin_mode]

  def execute(%{pin_number: pin_num, pin_mode: mode, label: label}, _, env) do
    env = mutate_env(env)
    case Farmbot.Firmware.read_pin(pin_num, mode) do
      :ok ->
        case Farmbot.BotState.get_pin_value(pin_num) do
          {:ok, val} ->
            Logger.info 2, "Read pin: #{pin_num} value: #{val}"
            Farmbot.CeleryScript.var(env, label, val)
          {:error, reason} -> {:error, reason, env}
        end
      {:error, reason} -> {:error, reason, env}
    end
  end
end
