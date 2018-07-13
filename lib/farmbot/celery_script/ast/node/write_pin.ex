defmodule Farmbot.CeleryScript.AST.Node.WritePin do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  use Farmbot.Logger
  alias Farmbot.CeleryScript.AST
  alias AST.Node.NamedPin
  alias Farmbot.Asset
  alias Asset.{Peripheral, Sensor}

  allow_args [:pin_number, :pin_value, :pin_mode]

  def execute(%{pin_number: %AST{kind: NamedPin} = named_pin, pin_mode: mode, pin_value: val}, _body, env) do
    env = mutate_env(env)
    id = named_pin.args.pin_id
    type = named_pin.args.pin_type
    case fetch_resource(type, id) do
      {:ok, %Peripheral{pin: num, label: name}} ->
        do_write(env, num, mode, val, "Peripheral #{name}")
      {:ok, %Sensor{pin: num, label: name}} ->
        do_write(env, num, mode, val, "Sensor #{name}")
      {:error, reason} -> {:error, reason, env}
    end
  end

  def execute(%{pin_mode: mode, pin_value: value, pin_number: num}, [], env) do
    env = mutate_env(env)
    do_write(env, num, mode, value, "pin")
  end

  defp do_write(env, num, mode, value, msg) do
    env = mutate_env(env)
    case Farmbot.Firmware.write_pin(num, mode, value) do
      :ok ->
        log_success(msg, num, mode, value)
        {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp log_success(msg, num, :digital, 1) do
    Logger.success 1, "Write #{msg} #{num} ON (1)"
  end

  defp log_success(msg, num, :digital, 0) do
    Logger.success 1, "Write #{msg} #{num} OFF (0)"
  end

  defp log_success(msg, num, _, val) do
    Logger.success 1, "Write #{msg} #{num}: #{val} (analog)"
  end

  defp fetch_resource(Peripheral, id) do
    case Asset.get_peripheral_by_id(id) do
      %Peripheral{} = per -> {:ok, per}
      nil -> {:error, "Could not find pin by id: #{id}"}
    end
  end

  defp fetch_resource(Sensor, id) do
    case Asset.get_sensor_by_id(id) do
      %Sensor{} = sen -> {:ok, sen}
      nil -> {:error, "Could not find pin by id: #{id}"}
    end
  end
end
