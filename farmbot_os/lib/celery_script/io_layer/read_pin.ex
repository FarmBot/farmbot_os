defmodule Farmbot.OS.IOLayer.ReadPin do
  alias Csvm.AST
  require Farmbot.Logger
  alias Farmbot.Asset
  alias Asset.{Peripheral, Sensor}

  @digital 0
  @analog 1

  def execute(%{pin_number: %AST{kind: :named_pin} = named_pin, pin_mode: mode}, _) do
    id = named_pin.args.pin_id
    type = named_pin.args.pin_type
    case fetch_resource(type, id) do
      %Peripheral{pin: pin_num, label: name} -> do_read(pin_num, mode, name)
      %Sensor{pin: pin_num, label: name} -> do_read(pin_num, mode, name)
      {:error, reason} -> {:error, reason}
    end
  end

  def execute(%{pin_number: pin_num, pin_mode: mode}, _) when is_number(pin_num) do
    case fetch_resource(nil, pin_num) do
      %Peripheral{pin: pin_num, label: name} ->
        do_read(pin_num, mode, name)
      %Sensor{pin: pin_num, label: name} ->
        do_read(pin_num, mode, name)
      {:ok, ^pin_num} ->
        do_read(pin_num, mode, "Pin #{pin_num}")
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_read(pin_num, mode, msg) do
    case Farmbot.Firmware.read_pin(pin_num, mode) do
      :ok ->
        case Farmbot.Firmware.get_pin_value(pin_num) do
          %{mode: ^mode, value: val} ->
            log_success(msg, pin_num, mode, val)
            :ok
          nil -> {:error, "Firmware didn't report pin value."}
        end
      {:error, reason} -> {:error, reason}
    end
  end

  defp log_success(msg, _num, @digital, 1) do
    Farmbot.Logger.success 1, "#{msg} value is 1 (digital)"
  end

  defp log_success(msg, _num, @digital, 0) do
    Farmbot.Logger.success 1, "#{msg} value is 0 (digital)"
  end

  defp log_success(msg, _num, @analog, val) do
    Farmbot.Logger.success 1, "#{msg} value is #{val} (analog)"
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
end
