defmodule FarmbotOS.SysCalls do
  require FarmbotCore.Logger
  require Logger

  alias FarmbotCeleryScript.AST
  alias FarmbotFirmware

  alias FarmbotCore.Asset.{
    BoxLed,
    Private
  }

  alias FarmbotOS.SysCalls.{
    ChangeOwnership,
    CheckUpdate,
    DumpInfo,
    Farmware,
    FactoryReset,
    FlashFirmware,
    SendMessage,
    SetPinIOMode,
    PinControl
  }

  alias FarmbotOS.Lua

  alias FarmbotCore.{Asset, Asset.Repo, Asset.Private, Asset.Sync, BotState, Leds}
  alias FarmbotExt.{API, API.Reconciler, API.SyncGroup}

  @behaviour FarmbotCeleryScript.SysCalls

  @impl true
  defdelegate send_message(level, message, channels), to: SendMessage

  @impl true
  defdelegate execute_script(name, env), to: Farmware

  @impl true
  defdelegate update_farmware(name), to: Farmware

  @impl true
  defdelegate flash_firmware(package), to: FlashFirmware

  @impl true
  defdelegate change_ownership(email, secret, server), to: ChangeOwnership

  @impl true
  defdelegate dump_info(), to: DumpInfo

  @impl true
  defdelegate check_update(), to: CheckUpdate

  @impl true
  defdelegate read_status(), to: FarmbotExt.AMQP.BotStateChannel

  @impl true
  defdelegate factory_reset(package), to: FactoryReset

  @impl true
  defdelegate set_pin_io_mode(pin, mode), to: SetPinIOMode

  @impl true
  defdelegate eval_assertion(comment, expression), to: Lua
  defdelegate log_assertion(passed?, type, message), to: Lua

  @impl true
  defdelegate read_pin(number, mode), to: PinControl

  @impl true
  defdelegate write_pin(number, mode, value), to: PinControl

  @impl true
  defdelegate toggle_pin(number), to: PinControl

  @impl true
  def log(message, force?) do
    if force? || FarmbotCore.Asset.fbos_config(:sequence_body_log) do
      FarmbotCore.Logger.info(2, message)
      :ok
    else
      :ok
    end
  end

  @impl true
  def sequence_init_log(message) do
    if FarmbotCore.Asset.fbos_config(:sequence_init_log) do
      FarmbotCore.Logger.info(2, message)
      :ok
    else
      :ok
    end
  end

  @impl true
  def sequence_complete_log(message) do
    if FarmbotCore.Asset.fbos_config(:sequence_complete_log) do
      FarmbotCore.Logger.info(2, message)
      :ok
    else
      :ok
    end
  end

  @impl true
  def reboot do
    FarmbotOS.System.reboot("Reboot requested by Sequence or frontend")
    :ok
  end

  @impl true
  def power_off do
    FarmbotOS.System.shutdown("Shut down requested by Sequence or frontend")
    :ok
  end

  @impl true
  def firmware_reboot do
    GenServer.stop(FarmbotFirmware, :reboot)
  end

  @impl true
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

  @impl true
  def set_user_env(key, value) do
    with {:ok, fwe} <- Asset.new_farmware_env(%{key: key, value: value}),
         _ <- Private.mark_dirty!(fwe) do
      :ok
    else
      {:error, reason} ->
        {:error, inspect(reason)}

      error ->
        {:error, inspect(error)}
    end
  end

  @impl true
  def get_current_x do
    get_position(:x)
  end

  @impl true
  def get_current_y do
    get_position(:y)
  end

  @impl true
  def get_current_z do
    get_position(:z)
  end

  @impl true
  def zero(axis) do
    axis = assert_axis!(axis)

    case FarmbotFirmware.command({:position_write_zero, [axis]}) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, "Firmware error: #{inspect(reason)}"}
    end
  end

  @impl true
  def point(kind, id) do
    case Asset.get_point(id: id) do
      nil -> {:error, "#{kind} not found"}
      %{x: x, y: y, z: z} -> %{x: x, y: y, z: z}
    end
  end

  def get_position() do
    case FarmbotFirmware.request({nil, {:position_read, []}}) do
      {:ok, {_, {:report_position, params}}} ->
        params

      {:error, reason} ->
        {:error, "Firmware error: #{inspect(reason)}"}
    end
  end

  def get_position(axis) do
    axis = assert_axis!(axis)

    case get_position() do
      {:error, _} = error -> error
      position -> Keyword.fetch!(position, axis)
    end
  end

  @impl true
  def move_absolute(x, y, z, speed) do
    do_move_absolute(x, y, z, speed, max_retries())
  end

  defp do_move_absolute(x, y, z, speed, retries, errors \\ [])

  defp do_move_absolute(x, y, z, speed, 0, errors) do
    params = [x: x / 1.0, y: y / 1.0, z: z / 1.0, s: speed / 1.0]

    case FarmbotFirmware.command({nil, {:command_movement, params}}) do
      :ok ->
        :ok

      {:error, reason} ->
        errors =
          [reason | errors]
          |> Enum.reverse()
          |> Enum.map(&inspect/1)
          |> Enum.join(", ")

        {:error, "movement error(s): #{errors}"}
    end
  end

  defp do_move_absolute(x, y, z, speed, retries, errors) do
    params = [x: x / 1.0, y: y / 1.0, z: z / 1.0, s: speed / 1.0]

    case FarmbotFirmware.command({nil, {:command_movement, params}}) do
      :ok ->
        :ok

      {:error, :emergency_lock} ->
        {:error, "emergency_lock"}

      {:error, reason} ->
        FarmbotCore.Logger.error(1, "Movement failed. Retrying up to #{retries} more time(s)")
        do_move_absolute(x, y, z, speed, retries - 1, [reason | errors])
    end
  end

  defp max_retries do
    case FarmbotFirmware.request({:parameter_read, [:param_mov_nr_retry]}) do
      {:ok, {_, {:report_parameter_value, [param_mov_nr_retry: nr]}}} -> floor(nr)
      _ -> 3
    end
  end

  @impl true
  def calibrate(axis) do
    axis = assert_axis!(axis)

    case FarmbotFirmware.command({:command_movement_calibrate, [axis]}) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, "Firmware error: #{inspect(reason)}"}
    end
  end

  @impl true
  def find_home(axis) do
    axis = assert_axis!(axis)

    case FarmbotFirmware.command({:command_movement_find_home, [axis]}) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, "Firmware error: #{inspect(reason)}"}
    end
  end

  @impl true
  def home(axis, _speed) do
    # TODO(Connor) fix speed
    axis = assert_axis!(axis)

    case FarmbotFirmware.command({:command_movement_home, [axis]}) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, "Firmware error: #{inspect(reason)}"}
    end
  end

  @impl true
  def emergency_lock do
    _ = FarmbotFirmware.command({:command_emergency_lock, []})
    :ok
  end

  @impl true
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

  @impl true
  def wait(ms) do
    Process.sleep(ms)
    :ok
  end

  @impl true
  def named_pin("Peripheral", id) do
    case Asset.get_peripheral(id: id) do
      %{} = peripheral -> peripheral
      nil -> {:error, "Could not find peripheral by id: #{id}"}
    end
  end

  def named_pin("Sensor", id) do
    case Asset.get_sensor(id) do
      %{} = sensor -> sensor
      nil -> {:error, "Could not find peripheral by id: #{id}"}
    end
  end

  def named_pin("BoxLed" <> id, _) do
    %BoxLed{id: String.to_integer(id)}
  end

  def named_pin(kind, id) do
    {:error, "unknown pin kind: #{kind} of id: #{id}"}
  end

  @impl true
  def get_sequence(id) do
    case Asset.get_sequence(id) do
      nil ->
        {:error, "sequence not found"}

      %{} = sequence ->
        ast = AST.decode(sequence)
        args = Map.put(ast.args, :sequence_name, sequence.name)
        %{%{ast | args: args} | meta: %{sequence_name: sequence.name}}
    end
  end

  @impl true
  def get_toolslot_for_tool(id) do
    with %{id: ^id} <- Asset.get_tool(id: id),
         %{x: x, y: y, z: z} <- Asset.get_point(tool_id: id) do
      %{x: x, y: y, z: z}
    else
      nil -> {:error, "Could not find point for tool by id: #{id}"}
    end
  end

  @impl true
  def sync() do
    FarmbotCore.Logger.busy(3, "Syncing")

    with {:ok, sync_changeset} <- API.get_changeset(Sync),
         :ok <- BotState.set_sync_status("syncing"),
         _ <- Leds.green(:fast_blink),
         sync_changeset <- Reconciler.sync_group(sync_changeset, SyncGroup.group_0()),
         sync_changeset <- Reconciler.sync_group(sync_changeset, SyncGroup.group_1()),
         sync_changeset <- Reconciler.sync_group(sync_changeset, SyncGroup.group_2()),
         sync_changeset <- Reconciler.sync_group(sync_changeset, SyncGroup.group_3()),
         _sync_changeset <- Reconciler.sync_group(sync_changeset, SyncGroup.group_4()) do
      FarmbotCore.Logger.success(3, "Synced")
      :ok = BotState.set_sync_status("synced")
      _ = Leds.green(:solid)
      :ok
    else
      error ->
        :ok = BotState.set_sync_status("sync_error")
        _ = Leds.green(:slow_blink)
        {:error, inspect(error)}
    end
  end

  @impl true
  def coordinate(x, y, z) do
    %{x: x, y: y, z: z}
  end

  @impl true
  def set_servo_angle(_pin, _angle) do
    {:error, "set_servo_angle not yet supported"}
  end

  @impl true
  def install_first_party_farmware() do
    {:error, "install_first_party_farmware not yet supported"}
  end

  @impl true
  def nothing(), do: nil
end
