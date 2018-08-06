defmodule Farmbot.OS.IOLayer do
  @behaviour Farmbot.Core.CeleryScript.IOLayer
  alias Farmbot.OS.IOLayer.{
    Farmware,
    FindHome,
    If,
    MoveAbsolute,
    ReadPin,
    Sync,
    TogglePin,
    WritePin,
  }

  def emergency_lock(_args, _body), do: Farmbot.Firmware.emergency_lock()

  def emergency_unlock(_args, _body), do: Farmbot.Firmware.emergency_unlock()

  def move_relative(%{x: x, y: y, z: z, speed: speed}, []) do
    import Farmbot.Core.CeleryScript.Utils
    %{x: cur_x, y: cur_y, z: cur_z} = Farmbot.Firmware.get_current_position()
    location = new_vec3(cur_x, cur_y, cur_z)
    offset = new_vec3(x, y, z)
    move_absolute(%{location: location, offset: offset, speed: speed}, [])
  end

  def move_absolute(args, body), do: MoveAbsolute.execute(args, body)

  def toggle_pin(args, body), do: TogglePin.execute(args, body)

  def write_pin(args, body), do: WritePin.execute(args, body)

  def read_pin(args, body), do: ReadPin.execute(args, body)

  def set_servo_angle(%{pin_number: pin_number, pin_value: value}, []) do
    case Farmbot.Firmware.set_servo_angle(pin_number, value) do
      :ok -> :ok
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
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

  def find_home(args, body), do: FindHome.execute(args, body)

  def wait(%{milliseconds: millis}, []), do: Process.sleep(millis)

  def zero(_args, _body) do
    {:error, "not implemented: zero"}
  end

  def calibrate(_args, _body) do
    {:error, "not implemented: calibrate"}
  end

  def config_update(_args, _body) do
    {:error, "config_update depreciated since 6.1.0"}
  end

  def set_user_env(_args, _body) do
    IO.inspect {:error, "not implemented: set_user_env"}
    :ok
  end

  def install_first_party_farmware(args, body), do: Farmware.first_party(args, body)

  def install_farmware(args, body), do: Farmware.install(args, body)

  def remove_farmware(args, body), do: Farmware.remove(args, body)

  def update_farmware(args, body), do: Farmware.update(args, body)

  def execute_script(args, body), do: Farmware.execute(args, body)

  def take_photo(_args, body) do
    execute_script(%{package: "take-photo"}, body)
  end

  def read_status(_args, _body) do
    Farmbot.BotState.fetch()
    :ok
  end

  def send_message(_args, _body) do
    {:error, "not implemented: send_message"}
  end

  def sync(args, body), do: Sync.execute(args, body)

  def power_off(_,_), do: Farmbot.System.shutdown("CeleryScript")

  def reboot(_,_), do: Farmbot.System.reboot("CeleryScript")

  def factory_reset(_,_), do: Farmbot.System.factory_reset("CeleryScript")

  def dump_info(_args, _body) do
    {:error, "not implemented: dump_info"}
  end

  def change_ownership(_args, _body) do
    {:error, "not implemented: change_ownership"}
  end

  def check_updates(_args, _body) do
    {:error, "not implemented: check_updates"}
  end

  def _if(args, body), do: If.execute(args, body)

  def execute(%{sequence_id: sid}, _body) do
    alias Farmbot.Asset
    case Asset.get_sequence_by_id(sid) do
      nil -> {:error, "no sequence by id: #{sid}"}
      %Asset.Sequence{} = seq -> {:ok, Farmbot.CeleryScript.AST.decode(seq)}
    end
  end
end
