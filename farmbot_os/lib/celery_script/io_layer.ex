defmodule Farmbot.OS.IOLayer do
  @moduledoc false
  @behaviour Farmbot.Core.CeleryScript.IOLayer
  alias Farmbot.OS.IOLayer.{
    MoveAbsolute,
    MoveRelative,
    ReadPin,
    Sync,
    TogglePin,
    WritePin
  }

  def calibrate(_args, _body), do: {:error, "Stubbed"}
  def change_ownership(_args, _body), do: {:error, "Stubbed"}
  def check_updates(_args, _body), do: {:error, "Stubbed"}
  def config_update(_args, _body), do: {:error, "Stubbed"}
  def dump_info(_args, _body), do: {:error, "Stubbed"}
  def emergency_lock(_args, _body), do: {:error, "Stubbed"}
  def emergency_unlock(_args, _body), do: {:error, "Stubbed"}
  def execute(_args, _body), do: {:error, "Stubbed"}
  def execute_script(_args, _body), do: {:error, "Stubbed"}
  def factory_reset(_args, _body), do: {:error, "Stubbed"}
  def find_home(_args, _body), do: {:error, "Stubbed"}
  def home(_args, _body), do: {:error, "Stubbed"}

  def move_absolute(args, body), do: require_firmware(MoveAbsolute, args, body)
  def move_relative(args, body), do: require_firmware(MoveRelative, args, body)

  def power_off(_args, _body), do: Farmbot.System.power_off("CeleryScript")

  def read_pin(args, body), do: require_firmware(ReadPin, args, body)

  def read_status(_args, _body) do
    Farmbot.BotState.fetch()
    :ok
  end

  def reboot(_args, _body), do: Farmbot.System.reboot("CeleryScript")

  def send_message(_args, _body), do: {:error, "Stubbed"}
  def set_servo_angle(_args, _body), do: {:error, "Stubbed"}

  def set_user_env(_args, body) do
    for %{args: %{label: key, value: value}} <- body do
      Farmbot.Asset.new_farmware_env(%{key: key, value: value})
    end

    :ok
  end

  def sync(args, body), do: Sync.execute(args, body)

  def take_photo(_args, _body), do: {:error, "Stubbed"}
  def toggle_pin(args, body), do: require_firmware(TogglePin, args, body)
  def wait(_args, _body), do: {:error, "Stubbed"}
  def write_pin(args, body), do: require_firmware(WritePin, args, body)
  def zero(_args, _body), do: {:error, "Stubbed"}
  def _if(_args, _body), do: {:error, "Stubbed"}

  defp require_firmware(module, args, body) do
    if Process.whereis(Farmbot.Firmware) do
      module.execute(args, body)
    else
      {:error, "Firmware not initialized"}
    end
  end
end
