defmodule Farmbot.OS.IOLayer do
  @moduledoc false
  @behaviour Farmbot.Core.CeleryScript.IOLayer
  alias Farmbot.OS.IOLayer.{
    Calibrate,
    FindHome,
    Home,
    MoveAbsolute,
    MoveRelative,
    ReadPin,
    SendMessage,
    SetServoAngle,
    Sync,
    TogglePin,
    WritePin,
    Zero
  }

  # Reporting commands
  def read_status(_args, _body) do
    Farmbot.BotState.fetch()
    :ok
  end

  def send_message(args, body), do: SendMessage.execute(args, body)

  def dump_info(_args, _body), do: {:error, "dump_info Stubbed"}

  # Flow Control
  def _if(_args, _body), do: {:error, "_if Stubbed"}

  def execute(%{sequence_id: id}, _body) do
    case Farmbot.Asset.get_sequence(id: id) do
      nil -> {:error, "Sequence #{id} not found. Try syncing first."}
      %{} = seq -> {:ok, Farmbot.CeleryScript.AST.decode(seq)}
    end
  end

  def wait(%{milliseconds: ms}, _body), do: Process.sleep(ms)

  # Emergency control
  def emergency_lock(_args, _body) do
    if Process.whereis(Farmbot.Firmware) do
      _ = Farmbot.Firmware.command({:command_emergency_lock, []})
    end

    :ok
  end

  def emergency_unlock(_args, _body) do
    if Process.whereis(Farmbot.Firmware) do
      _ = Farmbot.Firmware.command({:command_emergency_unlock, []})
    end

    :ok
  end

  # Firmware commands
  def calibrate(args, body), do: require_firmware(Calibrate, args, body)
  def find_home(args, body), do: require_firmware(FindHome, args, body)
  def home(args, body), do: require_firmware(Home, args, body)
  def move_absolute(args, body), do: require_firmware(MoveAbsolute, args, body)
  def move_relative(args, body), do: require_firmware(MoveRelative, args, body)
  def read_pin(args, body), do: require_firmware(ReadPin, args, body)
  def set_servo_angle(args, body), do: require_firmware(SetServoAngle, args, body)
  def toggle_pin(args, body), do: require_firmware(TogglePin, args, body)
  def write_pin(args, body), do: require_firmware(WritePin, args, body)
  def zero(args, body), do: require_firmware(Zero, args, body)

  # Farmware
  def set_user_env(_args, body) do
    for %{args: %{label: key, value: value}} <- body do
      Farmbot.Asset.new_farmware_env(%{key: key, value: value})
    end

    :ok
  end

  def take_photo(_args, _body), do: {:error, "take_photo Stubbed"}

  def execute_script(_args, _body), do: {:error, "execute_script Stubbed"}

  # Sync/Data
  def check_updates(_args, _body), do: {:error, "check_updates Stubbed"}
  def sync(args, body), do: Sync.execute(args, body)

  # Power/System
  def change_ownership(_args, _body), do: {:error, "change_ownership Stubbed"}
  def factory_reset(_args, _body), do: Farmbot.System.factory_reset("CeleryScript")
  def power_off(_args, _body), do: Farmbot.System.shutdown("CeleryScript")
  def reboot(_args, _body), do: Farmbot.System.reboot("CeleryScript")

  # deprecated commands
  def config_update(_args, _body), do: {:error, "config_update deprecated"}

  defp require_firmware(module, args, body) do
    if Process.whereis(Farmbot.Firmware) do
      module.execute(args, body)
    else
      {:error, "Firmware not initialized"}
    end
  end
end
