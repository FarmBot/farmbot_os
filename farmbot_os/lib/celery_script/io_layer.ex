defmodule Farmbot.OS.IOLayer do
  @behaviour Farmbot.CeleryScript.IOLayer
  alias Farmbot.OS.IOLayer.{
    ReadPin,
    Sync,
    WritePin,
  }

  def write_pin(args, body) do
    WritePin.execute(args, body)
  end

  def read_pin(args, body) do
    ReadPin.execute(args, body)
  end

  def set_servo_angle(_args, _body) do
    {:error, "not implemented: set_servo_angle"}
  end

  def send_message(_args, _body) do
    {:error, "not implemented: send_message"}
  end

  def move_relative(_args, _body) do
    {:error, "not implemented: move_relative"}
  end

  def home(_args, _body) do
    {:error, "not implemented: home"}
  end

  def find_home(_args, _body) do
    {:error, "not implemented: find_home"}
  end

  def wait(_args, _body) do
    {:error, "not implemented: wait"}
  end

  def toggle_pin(_args, _body) do
    {:error, "not implemented: toggle_pin"}
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
