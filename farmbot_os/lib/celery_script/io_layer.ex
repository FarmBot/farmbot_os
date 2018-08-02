defmodule Farmbot.OS.IOLayer do
  @behaviour Farmbot.CeleryScript.IOLayer
  alias Farmbot.OS.IOLayer.{
    FindHome,
    ReadPin,
    Sync,
    TogglePin,
    WritePin,
  }

  def write_pin(args, body) do
    WritePin.execute(args, body)
  end

  def read_pin(args, body) do
    ReadPin.execute(args, body)
  end

  def set_servo_angle(%{pin_number: pin_number, pin_value: value}, []) do
    case Farmbot.Firmware.set_servo_angle(pin_number, value) do
      :ok -> :ok
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  def send_message(_args, _body) do
    {:error, "not implemented: send_message"}
  end

  def move_relative(%{x: x, y: y, z: z, speed: speed}, []) do
    import Farmbot.CeleryScript.Utils
    %{x: cur_x, y: cur_y, z: cur_z} = Farmbot.Firmware.get_current_position()
    location = new_vec3(cur_x, cur_y, cur_z)
    offset = new_vec3(x, y, z)
    move_absolute(%{location: location, offset: offset, speed: speed}, [])
  end

  def home(%{axis: "all"}, []) do
    case Farmbot.Firmware.home_all() do
      :ok -> :ok
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  def home(%{axis: axis}, []) do
    case Farmbot.Firmware.home(axis) do
      :ok -> :ok
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  def find_home(args, body) do
    FindHome.execute(args, body)
  end

  def wait(%{milliseconds: millis}, []) do
    Process.sleep(millis)
    :ok
  end

  def toggle_pin(args, body) do
    TogglePin.execute(args, body)
  end

  def execute_script(_args, _body) do
    {:error, "not implemented: execute_script"}
  end

  def zero(_args, _body) do
    {:error, "not implemented: zero"}
  end

  def calibrate(_args, _body) do
    {:error, "not implemented: calibrate"}
  end

  def take_photo(_args, _body) do
    {:error, "not implemented: take_photo"}
  end

  def config_update(_args, _body) do
    {:error, "not implemented: config_update"}
  end

  def set_user_env(_args, _body) do
    {:error, "not implemented: set_user_env"}
  end

  def install_first_party_farmware(_args, _body) do
    {:error, "not implemented: install_first_party_farmware"}
  end

  def install_farmware(_args, _body) do
    {:error, "not implemented: install_farmware"}
  end

  def uninstall_farmware(_args, _body) do
    {:error, "not implemented: uninstall_farmware"}
  end

  def update_farmware(_args, _body) do
    {:error, "not implemented: update_farmware"}
  end

  def read_status(_args, _body) do
    Farmbot.BotState.fetch()
    :ok
  end

  def sync(args, body) do
    Sync.execute(args, body)
  end

  def power_off(_args, _body) do
    {:error, "not implemented: power_off"}
  end

  def reboot(_args, _body) do
    {:error, "not implemented: reboot"}
  end

  def factory_reset(_args, _body) do
    {:error, "not implemented: factory_reset"}
  end

  def change_ownership(_args, _body) do
    {:error, "not implemented: change_ownership"}
  end

  def check_updates(_args, _body) do
    {:error, "not implemented: check_updates"}
  end

  def dump_info(_args, _body) do
    {:error, "not implemented: dump_info"}
  end

  def move_absolute(_args, _body) do
    {:error, "not implemented: move_absolute"}
  end

  def _if(_args, _body) do
    {:error, "not implemented: _if"}
  end

  def execute(%{sequence_id: sid}, _body) do
    case Farmbot.Asset.get_sequence_by_id(sid) do
      nil -> {:error, "no sequence by id: #{sid}"}
      %Farmbot.Asset.Sequence{} = seq ->
        IO.warn "FIXME"
        {:ok, Csvm.AST.decode(seq)}
    end
  end

  def emergency_lock(_args, _body) do
    {:error, "not implemented: emergency_lock"}
  end

  def emergency_unlock(_args, _body) do
    {:error, "not implemented: emergency_unlock"}
  end

end
