defmodule FarmbotOS.SysCalls do
  require FarmbotCore.Logger

  alias FarmbotCeleryScript.AST
  alias FarmbotFirmware

  alias FarmbotOS.SysCalls.{SendMessage, ExecuteScript, FlashFirmware}

  alias FarmbotCore.{Asset, Asset.Repo, Asset.Sync, BotState}
  alias FarmbotExt.{API, API.Reconciler, API.SyncGroup}
  alias Ecto.{Changeset, Multi}

  @behaviour FarmbotCeleryScript.SysCalls

  defdelegate send_message(level, message, channels), to: SendMessage
  defdelegate execute_script(name, env), to: ExecuteScript
  defdelegate flash_firmware(package), to: FlashFirmware

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
    case FarmbotFirmware.command({:command_movement_calibrate, axis}) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
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
