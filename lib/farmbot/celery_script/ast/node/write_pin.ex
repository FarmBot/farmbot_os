defmodule Farmbot.CeleryScript.AST.Node.WritePin do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  use Farmbot.Logger
  alias Farmbot.CeleryScript.AST
  alias AST.Node.NamedPin
  alias Farmbot.Repo.Context
  alias Farmbot.Repo.Peripheral

  allow_args [:pin_number, :pin_value, :pin_mode]

  def execute(%{pin_number: %AST{kind: NamedPin} = named_pin, pin_mode: mode, pin_value: val}, body, env) do
    env = mutate_env(env)
    id = named_pin.args.pin_id
    case Context.get_peripheral(id) do
      %Peripheral{pin: number} ->
        execute(%{pin_number: number, pin_mode: mode, pin_value: val}, body, env)
      nil -> {:error, "Could not find pin by id: #{id}", env}
    end
  end

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
