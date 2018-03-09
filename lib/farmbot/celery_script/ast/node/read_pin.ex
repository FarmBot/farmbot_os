defmodule Farmbot.CeleryScript.AST.Node.ReadPin do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  alias Farmbot.CeleryScript.AST
  alias AST.Node.NamedPin
  allow_args [:pin_number, :label, :pin_mode]
  use Farmbot.Logger
  alias Farmbot.Asset
  alias Asset.{Peripheral, Sensor}

  def execute(%{pin_number: %AST{kind: NamedPin} = named_pin, pin_mode: mode, label: label}, body, env) do
    env = mutate_env(env)
    id = named_pin.args.pin_id
    type = named_pin.args.pin_type
    case fetch_resource(type, id) do
      {:ok, number} ->
        execute(%{pin_number: number, pin_mode: mode, label: label}, body, env)
      {:error, reason} -> {:error, reason, env}
    end
  end

  def execute(%{pin_number: pin_num, pin_mode: mode, label: label}, _, env) when is_number(pin_num) do
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

  defp fetch_resource(Peripheral, id) do
    case Asset.get_peripheral_by_id(id) do
      %Peripheral{pin: number} -> {:ok, number}
      nil -> {:error, "Could not find pin by id: #{id}"}
    end
  end

  defp fetch_resource(Sensor, id) do
    case Asset.get_sensor_by_id(id) do
      %Sensor{pin: number} -> {:ok, number}
      nil -> {:error, "Could not find pin by id: #{id}"}
    end
  end

end
