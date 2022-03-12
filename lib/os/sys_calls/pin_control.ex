defmodule FarmbotOS.SysCalls.PinControl do
  @moduledoc false

  alias FarmbotOS.{Asset, Leds}
  alias FarmbotOS.Firmware.Command

  alias FarmbotOS.Asset.{
    BoxLed,
    Peripheral,
    Sensor
  }

  require FarmbotOS.Logger

  def read_cached_pin(%_{pin: number}) do
    read_cached_pin(number)
  end

  def read_cached_pin(pin_number) do
    FarmbotOS.BotState.fetch().pins()[pin_number][:value]
  end

  def toggle_pin(pin_number) when is_number(pin_number) do
    peripheral = Asset.get_peripheral_by_pin(pin_number)

    with {:ok, _} <- Command.set_pin_io_mode(pin_number, :output) do
      case Command.read_pin(pin_number, :digital) do
        {:ok, 1} -> do_toggle_pin(peripheral || pin_number, 0)
        {:ok, 0} -> do_toggle_pin(peripheral || pin_number, 1)
        reason -> FarmbotOS.SysCalls.give_firmware_reason("toggle_pin", reason)
      end
    else
      {:error, reason} ->
        FarmbotOS.SysCalls.give_firmware_reason("toggle_pin", reason)
    end
  end

  def toggle_pin(pin_number) do
    {:error, "Unknown pin data: #{inspect(pin_number)}"}
  end

  def set_servo_angle(pin, angle) do
    case Command.move_servo(pin, angle) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        FarmbotOS.SysCalls.give_firmware_reason("set_servo_angle", reason)
    end
  end

  defp do_toggle_pin(%Peripheral{pin: pin_number} = data, value) do
    with {:ok, _} <- Command.write_pin(pin_number, value, :digital),
         value when is_number(value) <- do_read_pin(data, 0) do
      :ok
    else
      reason ->
        FarmbotOS.SysCalls.give_firmware_reason(
          "do_toggle_pin:Peripheral",
          reason
        )
    end
  end

  defp do_toggle_pin(pin_number, value) do
    result = Command.write_pin(pin_number, value, 0)

    with {:ok, _} <- result,
         value when is_number(value) <- do_read_pin(pin_number, 0) do
      :ok
    else
      {:error, reason} ->
        FarmbotOS.SysCalls.give_firmware_reason("do_toggle_pin:int", reason)
    end
  end

  def read_pin(%Peripheral{pin: _} = data, mode) do
    do_read_pin(data, mode)
  end

  def read_pin(%Sensor{pin: pin} = data, mode) do
    case do_read_pin(data, mode) do
      {:error, _} = error ->
        error

      value ->
        now = DateTime.utc_now()
        position = FarmbotOS.SysCalls.get_position()

        params = %{
          pin: pin,
          mode: mode,
          value: value,
          x: position[:x],
          y: position[:y],
          z: position[:z],
          read_at: now
        }

        _ = Asset.new_sensor_reading!(params)
        value
    end
  end

  def read_pin(%BoxLed{}, _mode) do
    # {:error, "cannot read values of BoxLed"}
    1
  end

  def read_pin(pin_number, mode) when is_number(pin_number) do
    sensor = Asset.get_sensor_by_pin(pin_number)
    peripheral = Asset.get_peripheral_by_pin(pin_number)

    cond do
      is_map(sensor) ->
        read_pin(sensor, mode)

      is_map(peripheral) ->
        read_pin(peripheral, mode)

      true ->
        do_read_pin(pin_number, mode)
    end
  end

  # digital peripheral

  defp do_read_pin(%Peripheral{pin: pin_number, label: label}, 0)
       when is_number(pin_number) do
    case Command.read_pin(pin_number, 0) do
      {:ok, 1} ->
        FarmbotOS.Logger.info(
          2,
          "The #{label} peripheral value is ON (digital)"
        )

        1

      {:ok, 0} ->
        FarmbotOS.Logger.info(
          2,
          "The #{label} peripheral value is OFF (digital)"
        )

        0

      {:ok, value} ->
        FarmbotOS.Logger.info(
          2,
          "The #{label} peripheral value is #{value} (analog)"
        )

        value

      reason ->
        FarmbotOS.SysCalls.give_firmware_reason("do_read_pin", reason)
    end
  end

  # analog peripheral

  defp do_read_pin(%Peripheral{pin: pin_number, label: label}, 1)
       when is_number(pin_number) do
    case Command.read_pin(pin_number, 1) do
      {:ok, value} ->
        msg = "The #{label} peripheral value is #{value} (analog)"
        FarmbotOS.Logger.info(2, msg)
        value

      {:error, reason} ->
        place = "do_read_pin:Peripheral"
        FarmbotOS.SysCalls.give_firmware_reason(place, reason)
    end
  end

  # digital sensor

  defp do_read_pin(%Sensor{pin: pin_number, label: label}, 0)
       when is_number(pin_number) do
    case Command.read_pin(pin_number, 0) do
      {:ok, 1} ->
        FarmbotOS.Logger.info(2, "The #{label} sensor value is 1 (digital)")
        1

      {:ok, 0} ->
        FarmbotOS.Logger.info(2, "The #{label} sensor value is 0 (digital)")
        0

      {:ok, value} ->
        msg = "The #{label} sensor value is #{value} (analog)"
        FarmbotOS.Logger.info(2, msg)

      {:error, reason} ->
        FarmbotOS.SysCalls.give_firmware_reason("do_read_pin(%Sensor)", reason)
    end
  end

  # analog sensor

  defp do_read_pin(%Sensor{pin: pin_number, label: label}, 1)
       when is_number(pin_number) do
    case Command.read_pin(pin_number, 1) do
      {:ok, value} ->
        msg = "The #{label} sensor value is #{value} (analog)"
        FarmbotOS.Logger.info(2, msg)
        value

      {:error, reason} ->
        FarmbotOS.SysCalls.give_firmware_reason("do_read_pin(%Sensor)", reason)
    end
  end

  # Catches unsupplied `mode`
  defp do_read_pin(%type{mode: mode} = peripheral, nil)
       when type in [Peripheral, Sensor] do
    do_read_pin(peripheral, mode)
  end

  # Generic pin digital
  defp do_read_pin(pin_number, 0) when is_number(pin_number) do
    case Command.read_pin(pin_number, 0) do
      {:ok, 0} ->
        FarmbotOS.Logger.info(2, "Pin #{pin_number} value is OFF (digital)")
        0

      {:ok, 1} ->
        FarmbotOS.Logger.info(2, "Pin #{pin_number} value is ON (digital)")
        1

      {:ok, value} ->
        FarmbotOS.Logger.info(2, "Pin #{pin_number} is #{value} (analog)")
        value

      {:error, reason} ->
        FarmbotOS.SysCalls.give_firmware_reason(
          "do_read_pin(pin_number, 0)",
          reason
        )
    end
  end

  # Generic pin digital
  defp do_read_pin(pin_number, 1) when is_number(pin_number) do
    case Command.read_pin(pin_number, 1) do
      {:ok, value} ->
        FarmbotOS.Logger.info(2, "Pin #{pin_number} is #{value} (analog)")
        value

      {:error, reason} ->
        FarmbotOS.SysCalls.give_firmware_reason(
          "do_read_pin(pin_number, 1)",
          reason
        )
    end
  end

  # Peripheral digital
  def write_pin(%Peripheral{pin: pin, label: _label}, 0, 1) do
    do_write_pin(pin, 0, 1)
  end

  def write_pin(%Peripheral{pin: pin, label: _label}, 0, 0) do
    do_write_pin(pin, 0, 0)
  end

  # Peripheral analog
  def write_pin(%Peripheral{pin: pin, label: _label}, 1, value) do
    do_write_pin(pin, 1, value)
  end

  def write_pin(%Sensor{pin: _pin}, _mode, _value) do
    {:error, "cannot write Sensor value. Use a Peripheral"}
  end

  def write_pin(%BoxLed{id: 3}, 0, 1) do
    FarmbotOS.Logger.info(2, "Turning Boxled3 ON")
    Leds.white4(:solid)
    :ok
  end

  def write_pin(%BoxLed{id: 3}, 0, 0) do
    FarmbotOS.Logger.info(2, "Turning Boxled3 OFF")
    Leds.white4(:off)
    :ok
  end

  def write_pin(%BoxLed{id: 4}, 0, 1) do
    FarmbotOS.Logger.info(2, "Turning Boxled4 ON")
    Leds.white5(:solid)
    :ok
  end

  def write_pin(%BoxLed{id: 4}, 0, 0) do
    FarmbotOS.Logger.info(2, "Turning Boxled4 OFF")
    Leds.white5(:off)
    :ok
  end

  def write_pin(%BoxLed{id: id}, _mode, _) do
    {:error, "cannot write Boxled#{id} in analog mode"}
  end

  # Generic pin digital
  def write_pin(pin, 0, 1) do
    do_write_pin(pin, 0, 1)
  end

  def write_pin(pin, 0, 0) do
    do_write_pin(pin, 0, 0)
  end

  def write_pin(pin, 1, value) do
    do_write_pin(pin, 1, value)
  end

  def do_write_pin(pin_number, mode, value) do
    case Command.write_pin(pin_number, value, mode) do
      {:ok, _} ->
        FarmbotOS.BotState.set_pin_value(pin_number, value / 1, mode)
        :ok

      {:error, reason} ->
        FarmbotOS.SysCalls.give_firmware_reason("do_write_pin/3", reason)
    end
  end
end
