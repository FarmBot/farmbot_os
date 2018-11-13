defmodule Farmbot.OS.IOLayer do
  @behaviour Farmbot.Core.CeleryScript.IOLayer
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
  def move_absolute(_args, _body), do: {:error, "Stubbed"}
  def move_relative(_args, _body), do: {:error, "Stubbed"}

  def power_off(_args, _body), do: Farmbot.System.power_off("CeleryScript")

  def read_pin(%{pin_num: num, pin_mode: mode}, body)
    when is_integer(num)
    when is_integer(mode)
   do
    r = Farmbot.Firmware.request({:pin_read, [p: num, m: mode]})
    IO.inspect(r, label: "R")
    :ok
  end

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

  require Farmbot.Logger
  alias Farmbot.{Asset.Repo, Asset.Sync, API}
  alias API.{Reconciler, SyncGroup}
  alias Ecto.{Changeset, Multi}

  def sync(_args, _body) do
    Farmbot.Logger.busy(3, "Syncing")
    sync_changeset = API.get_changeset(Sync)
    sync = Changeset.apply_changes(sync_changeset)
    multi = Multi.new()

    :ok = Farmbot.BotState.set_sync_status("syncing")
    with {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_1()),
         {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_2()),
         {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_3()),
         {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_4()) do
      Multi.insert(multi, :syncs, sync_changeset)
      |> Repo.transaction()

      Farmbot.Logger.success(3, "Synced")
      :ok = Farmbot.BotState.set_sync_status("synced")
      :ok
    else
      error -> 
        :ok = Farmbot.BotState.set_sync_status("sync_error")
        {:error, inspect(error)}
    end
  end

  def take_photo(_args, _body), do: {:error, "Stubbed"}
  def toggle_pin(_args, _body), do: {:error, "Stubbed"}
  def wait(_args, _body), do: {:error, "Stubbed"}
  def write_pin(_args, _body), do: {:error, "Stubbed"}
  def zero(_args, _body), do: {:error, "Stubbed"}
  def _if(_args, _body), do: {:error, "Stubbed"}
end
