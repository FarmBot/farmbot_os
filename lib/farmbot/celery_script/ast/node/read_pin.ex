defmodule Farmbot.CeleryScript.AST.Node.ReadPin do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  alias Farmbot.CeleryScript.AST
  alias AST.Node.NamedPin
  allow_args [:pin_number, :label, :pin_mode]
  use Farmbot.Logger
  alias Farmbot.Asset
  alias Asset.{Peripheral, Sensor}

  def execute(%{pin_number: %AST{kind: NamedPin} = named_pin, pin_mode: mode, label: label}, _, env) do
    env = mutate_env(env)
    id = named_pin.args.pin_id
    type = named_pin.args.pin_type
    case fetch_resource(type, id) do
      {:ok, %Peripheral{pin: pin_num, label: name}} ->
        msg = "Peripheral #{name}"
        do_read(env, pin_num, mode, label, msg)
      {:ok, %Sensor{pin: pin_num, label: name}} ->
        msg = "Sensor #{name}"
        do_read(env, pin_num, mode, label, msg)
      {:error, reason} -> {:error, reason, env}
    end
  end

  def execute(%{pin_number: pin_num, pin_mode: mode, label: label}, _, env) when is_number(pin_num) do
    env = mutate_env(env)
    do_read(env, pin_num, mode, label, "pin")
  end

  defp do_read(env, pin_num, mode, label, msg) do
    case Farmbot.Firmware.read_pin(pin_num, mode) do
      :ok ->
        case Farmbot.BotState.get_pin_value(pin_num) do
          {:ok, val} ->
            log_success(msg, pin_num, mode, val)
            Farmbot.CeleryScript.var(env, label, val)
          {:error, reason} -> {:error, reason, env}
        end
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp log_success(msg, num, :digital, 1) do
    Logger.success 1, "Read #{msg} #{num} ON (1)"
  end

  defp log_success(msg, num, :digital, 0) do
    Logger.success 1, "Read #{msg} #{num} OFF (0)"
  end

  defp log_success(msg, num, _, val) do
    Logger.success 1, "Read #{msg} #{num}: #{val} (analog)"
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
