defmodule FarmbotOS.SysCalls do
  require FarmbotCore.Logger

  alias FarmbotCeleryScript.AST
  alias FarmbotFirmware

  alias FarmbotOS.SysCalls.{
    SendMessage,
    ExecuteScript,
    FlashFirmware,
    ChangeOwnership,
    DumpInfo
  }

  alias FarmbotCore.{Asset, Asset.Repo, Asset.Private, Asset.Sync, BotState}
  alias FarmbotExt.{API, API.Reconciler, API.SyncGroup}
  alias Ecto.{Changeset, Multi}

  @behaviour FarmbotCeleryScript.SysCalls

  defdelegate send_message(level, message, channels), to: SendMessage
  defdelegate execute_script(name, env), to: ExecuteScript
  defdelegate flash_firmware(package), to: FlashFirmware
  defdelegate change_ownership(email, secret), to: ChangeOwnership
  defdelegate dump_info(), to: DumpInfo

  def check_update do
    _ = FarmbotOS.Platform.Target.NervesHubClient.check_update()
    :ok
  end

  def reboot do
    FarmbotOS.System.reboot("Reboot requested by sequence or frontend")
    :ok
  end

  def power_off do
    FarmbotOS.System.reboot("Shut down requested by sequence or frontend")
    :ok
  end

  def factory_reset do
    FarmbotOS.System.factory_reset("Factory reset requested by sequence or frontent")
    :ok
  end

  def firmware_reboot do
    GenServer.stop(FarmbotFirmware, :reboot)
  end

  def resource_update(kind, id, params) do
    module = Module.concat(Asset, kind)

    with true <- Code.ensure_loaded?(module),
         %{} = orig <- Repo.get_by(module, [id: id], preload: [:local_meta]),
         %{valid?: true} = change <- module.changeset(orig, params),
         {:ok, new} <- Repo.update(change),
         new <- Repo.preload(new, [:local_meta]) do
      Private.mark_dirty!(new, %{})
      :ok
    else
      false ->
        {:error, "unknown asset kind: #{kind}"}

      nil ->
        {:error, "Could not find asset by kind: #{kind} and id: #{id}"}

      %{valid?: false} = changeset ->
        {:error, "failed to update #{kind}: #{inspect(changeset.errors)}"}
    end
  end

  def read_status do
    :ok = FarmbotExt.AMQP.BotStateNGChannel.force()
  end

  def set_user_env(key, value) do
    FarmbotCore.BotState.set_user_env(key, value)
  end

  def get_current_x do
    get_position(:x)
  end

  def get_current_y do
    get_position(:y)
  end

  def get_current_z do
    get_position(:z)
  end

  def read_pin(pin_number, mode) do
    case FarmbotFirmware.request({nil, {:pin_read, [p: pin_number, m: mode]}}) do
      {:ok, {_, {:report_pin_value, [p: _, v: val]}}} ->
        val

      {:error, reason} ->
        {:error, "Firmware error: #{inspect(reason)}"}
    end
  end

  def write_pin(pin_number, mode, value) do
    case FarmbotFirmware.command({:pin_write, [p: pin_number, v: value, m: mode]}) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, "Firmware error: #{inspect(reason)}"}
    end
  end

  def point(kind, id) do
    case Asset.get_point(id: id) do
      nil -> {:error, "#{kind} not found"}
      %{x: x, y: y, z: z} -> %{x: x, y: y, z: z}
    end
  end

  defp get_position(axis) do
    axis = assert_axis!(axis)

    case FarmbotFirmware.request({nil, {:position_read, []}}) do
      {:ok, {_, {:report_position, params}}} ->
        Keyword.fetch!(params, axis)

      {:error, reason} ->
        {:error, "Firmware error: #{inspect(reason)}"}
    end
  end

  def move_absolute(x, y, z, speed) do
    params = [x: x / 1.0, y: y / 1.0, z: z / 1.0, s: speed / 1.0]

    case FarmbotFirmware.command({nil, {:command_movement, params}}) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, "Firmware error: #{inspect(reason)}"}
    end
  end

  def calibrate(axis) do
    axis = assert_axis!(axis)

    case FarmbotFirmware.command({:command_movement_calibrate, axis}) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, "Firmware error: #{inspect(reason)}"}
    end
  end

  def find_home(axis) do
    axis = assert_axis!(axis)

    case FarmbotFirmware.command({:command_movement_find_home, axis}) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, "Firmware error: #{inspect(reason)}"}
    end
  end

  def emergency_lock do
    _ = FarmbotFirmware.command({:command_emergency_lock, []})
    :ok
  end

  def emergency_unlock do
    _ = FarmbotFirmware.command({:command_emergency_unlock, []})
    :ok
  end

  defp assert_axis!(axis) when is_atom(axis),
    do: axis

  defp assert_axis!(axis) when axis in ~w(x y z),
    do: String.to_existing_atom(axis)

  defp assert_axis!(axis) do
    # {:error, "unknown axis #{axis}"}
    raise("unknown axis #{axis}")
  end

  def wait(ms) do
    Process.sleep(ms)
    :ok
  end

  def named_pin(kind, id) do
    {:error, "unknown pin kind: #{kind} of id: #{id}"}
  end

  def get_sequence(id) do
    case Asset.get_sequence(id: id) do
      nil -> {:error, "sequence not found"}
      %{} = sequence -> AST.decode(sequence)
    end
  end

  def sync() do
    FarmbotCore.Logger.busy(3, "Syncing")
    sync_changeset = API.get_changeset(Sync)
    sync = Changeset.apply_changes(sync_changeset)
    multi = Multi.new()

    :ok = BotState.set_sync_status("syncing")

    with {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_0()),
         {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_1()),
         {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_2()),
         {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_3()),
         {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_4()) do
      Multi.insert(multi, :syncs, sync_changeset)
      |> Repo.transaction()

      FarmbotCore.Logger.success(3, "Synced")
      :ok = BotState.set_sync_status("synced")
      :ok
    else
      error ->
        :ok = BotState.set_sync_status("sync_error")
        {:error, inspect(error)}
    end
  end
end
