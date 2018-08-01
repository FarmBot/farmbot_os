defmodule Farmbot.OS.IOLayer.WritePin do
  alias Farmbot.CeleryScript.AST
  alias Farmbot.Asset
  alias Asset.Peripheral
  require Farmbot.Logger

  @digital 0
  @analog 1

  def execute(%{pin_number: %AST{kind: :named_pin, args: %{pin_type: "BoxLed3"}}, pin_mode: @digital, pin_value: value}, _body) do
    log_success("BoxLed3", "BoxLed3", @digital, value)
    Farmbot.Leds.white4(value_to_led(value))
    :ok
  end

  def execute(%{pin_number: %AST{kind: :named_pin, args: %{pin_type: "BoxLed4"}}, pin_mode: @digital, pin_value: value}, _body) do
    log_success("BoxLed4", "BoxLed4", @digital, value)
    Farmbot.Leds.white5(value_to_led(value))
    :ok
  end

  def execute(%{pin_number: %AST{kind: :named_pin} = named_pin, pin_mode: mode, pin_value: val}, _body) do
    id = named_pin.args.pin_id
    type = named_pin.args.pin_type
    case fetch_resource(type, id) do
      %Peripheral{pin: num, label: name} -> do_write(num, mode, val, name)
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  def execute(%{pin_mode: mode, pin_value: value, pin_number: num}, []) do
    case fetch_resource(nil, num) do
      %Peripheral{pin: num, label: name} ->
        do_write(num, mode, value, name)
      {:ok, ^num} -> do_write(num, mode, value, "Pin #{num}")
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  defp do_write(num, mode, value, msg) do
    case Farmbot.Firmware.write_pin(num, mode, value) do
      :ok ->
        log_success(msg, num, mode, value)
        :ok
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  defp log_success(msg, _num, @digital, 1) do
    Farmbot.Logger.success 1, "#{msg} turned ON"
  end

  defp log_success(msg, _num, @digital, 0) do
    Farmbot.Logger.success 1, "#{msg} turned OFF"
  end

  defp log_success(msg, _num, @analog, val) do
    Farmbot.Logger.success 1, "#{msg} set to #{val} (analog)"
  end

  defp fetch_resource("Peripheral", id) do
    case Asset.get_peripheral_by_id(id) do
      %Peripheral{} = per -> per
      nil -> {:error, "Could not find pin by id: #{id}"}
    end
  end

  defp fetch_resource(nil, number) do
    try_lookup_peripheral(number) || {:ok, number}
  end

  defp try_lookup_peripheral(number) do
    Asset.get_peripheral_by_number(number)
  end

  defp value_to_led(1), do: :solid
  defp value_to_led(_), do: :off
end
