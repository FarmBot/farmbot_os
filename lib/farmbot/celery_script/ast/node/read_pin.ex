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
      %Peripheral{pin: pin_num, label: name} -> 
        do_read(env, Peripheral, pin_num, mode, label, name)

      %Sensor{pin: pin_num, label: name} -> 
        do_read(env, Sensor, pin_num, mode, label, name)

      {:error, reason} -> {:error, reason, env}
    end
  end

  def execute(%{pin_number: pin_num, pin_mode: mode, label: label}, _, env) when is_number(pin_num) do
    env = mutate_env(env)
    case fetch_resource(nil, pin_num) do
      %Peripheral{pin: pin_num, label: name} ->
        do_read(env, Peripheral, pin_num, mode, label, name)

      %Sensor{pin: pin_num, label: name} ->
        do_read(env, Sensor, pin_num, mode, label, name)

      {:ok, ^pin_num} ->
        do_read(env, nil, pin_num, mode, label, "Pin #{pin_num}")

      {:error, reason} -> {:error, reason, env}
    end
  end

  defp do_read(env, type, pin_num, mode, label, msg) do
    case Farmbot.Firmware.read_pin(pin_num, mode) do
      :ok ->
        case Farmbot.BotState.get_pin_value(pin_num) do
          {:ok, val} ->
            maybe_http_side_effects(type, pin_num, mode, val)
            log_success(msg, pin_num, mode, val)
            Farmbot.CeleryScript.var(env, label, val)
          {:error, reason} -> {:error, reason, env}
        end
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp log_success(msg, _num, :digital, 1) do
    Logger.success 1, "#{msg} value is 1 (digital)"
  end

  defp log_success(msg, _num, :digital, 0) do
    Logger.success 1, "#{msg} value is 0 (digital)"
  end

  defp log_success(msg, _num, _, val) do
    Logger.success 1, "#{msg} value is #{val} (analog)"
  end

  defp fetch_resource(Peripheral, id) do
    case Asset.get_peripheral_by_id(id) do
      %Peripheral{} = per -> per
      nil -> {:error, "Could not find pin by id: #{id}"}
    end
  end

  defp fetch_resource(Sensor, id) do
    case Asset.get_sensor_by_id(id) do
      %Sensor{} = sen -> sen
      nil -> {:error, "Could not find pin by id: #{id}"}
    end
  end

  defp fetch_resource(nil, number) do
    try_lookup_sensor(number) ||
    try_lookup_peripheral(number) ||
    {:ok, number}
  end

  defp try_lookup_peripheral(number) do
    Asset.get_peripheral_by_number(number)
  end

  defp try_lookup_sensor(number) do
    Asset.get_sensor_by_number(number)
  end

  defp maybe_http_side_effects(Sensor, pin_num, mode, value) when is_atom(mode) do
    %{x: _x, y: _y, z: _z} = pos = Farmbot.BotState.get_current_pos()
    mode = if mode == :digital, do: 0, else: 1
    payload = Map.merge(pos, %{
      pin: pin_num,
      mode: mode,
      value: value
      }) |> Farmbot.JSON.encode!()
      Farmbot.HTTP.post("/api/sensor_readings", payload)
      Logger.debug 3, "Sending Reading to API"
      
    :ok
  end

  defp maybe_http_side_effects(_, _, mode, _) when is_atom(mode), do: :ok
end
