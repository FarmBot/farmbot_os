defmodule FarmbotOS.SysCalls do
  require FarmbotCore.Logger
  require Logger

  alias FarmbotCeleryScript.AST
  alias FarmbotFirmware

  alias FarmbotOS.SysCalls.{
    ChangeOwnership,
    CheckUpdate,
    DumpInfo,
    ExecuteScript,
    FlashFirmware,
    SendMessage
  }

  alias FarmbotCore.{Asset, Asset.Repo, Asset.Private, Asset.Sync, BotState, Leds}
  alias FarmbotExt.{API, API.Reconciler, API.SyncGroup}
  alias Ecto.{Changeset, Multi}

  @behaviour FarmbotCeleryScript.SysCalls

  @impl true
  defdelegate send_message(level, message, channels), to: SendMessage

  @impl true
  defdelegate execute_script(name, env), to: ExecuteScript

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
  def reboot do
    FarmbotOS.System.reboot("Reboot requested by Sequence or frontend")
    :ok
  end

  @impl true
  def power_off do
    FarmbotOS.System.reboot("Shut down requested by Sequence or frontend")
    :ok
  end

  @impl true
  def factory_reset do
    FarmbotOS.System.factory_reset("Factory reset requested by Sequence or frontend", true)
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
    FarmbotCore.BotState.set_user_env(key, value)
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
  def read_pin({:peripheral, %{pin: pin}}, mode) do
    do_read_pin(pin, mode)
  end

  def read_pin({:sensor, %{pin: pin}}, mode) do
    case do_read_pin(pin, mode) do
      {:error, _} = error ->
        error

      value ->
        position = get_position()

        params = %{
          pin: pin,
          mode: mode,
          value: value,
          x: position[:x],
          y: position[:y],
          z: position[:z]
        }

        _ = Asset.new_sensor_reading!(params)
        value
    end
  end

  def read_pin({:box_led, _id}, _mode) do
    # {:error, "cannot read values of BoxLed"}
    1
  end

  def read_pin(pin_number, mode) when is_number(pin_number) do
    sensor = Asset.get_sensor_by_pin(pin_number)
    peripheral = Asset.get_peripheral_by_pin(pin_number)

    cond do
      is_map(sensor) ->
        read_pin({:sensor, sensor}, mode)

      is_map(peripheral) ->
        read_pin({:peripheral, peripheral}, mode)

      true ->
        do_read_pin(pin_number, mode)
    end
  end

  defp do_read_pin(pin_number, mode) do
    case FarmbotFirmware.request({:pin_read, [p: pin_number, m: mode]}) do
      {:ok, {_, {:report_pin_value, [p: _, v: val]}}} ->
        val

      {:error, reason} ->
        {:error, "Firmware error: #{inspect(reason)}"}
    end
  end

  @impl true
  def write_pin({:peripheral, %{pin: pin}}, mode, value) do
    write_pin(pin, mode, value)
  end

  def write_pin({:sensor, %{pin: _pin}}, _mode, _value) do
    {:error, "cannot write Sensor value. Use a Peripheral"}
  end

  def write_pin({:box_led, 3}, _mode, value) do
    Leds.white4(value_to_led(value))
    :ok
  end

  def write_pin({:box_led, 4}, _mode, value) do
    Leds.white5(value_to_led(value))
    :ok
  end

  def write_pin(pin_number, mode, value) do
    case FarmbotFirmware.command({:pin_write, [p: pin_number, v: value, m: mode]}) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, "Firmware error: #{inspect(reason)}"}
    end
  end

  defp value_to_led(1), do: :solid
  defp value_to_led(_), do: :off

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
    params = [x: x / 1.0, y: y / 1.0, z: z / 1.0, s: speed / 1.0]
    # Logger.debug "moving to location: #{inspect(params)}"

    case FarmbotFirmware.command({nil, {:command_movement, params}}) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, "Firmware error: #{inspect(reason)}"}
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
      %{} = peripheral -> {:peripheral, peripheral}
      nil -> {:error, "Could not find peripheral by id: #{id}"}
    end
  end

  def named_pin("Sensor", id) do
    case Asset.get_sensor(id) do
      %{} = sensor -> {:sensor, sensor}
      nil -> {:error, "Could not find peripheral by id: #{id}"}
    end
  end

  def named_pin("BoxLed" <> id, _) do
    {:box_led, String.to_integer(id)}
  end

  def named_pin(kind, id) do
    {:error, "unknown pin kind: #{kind} of id: #{id}"}
  end

  @impl true
  def get_sequence(id) do
    case Asset.get_sequence(id) do
      nil -> {:error, "sequence not found"}
      %{} = sequence -> AST.decode(sequence)
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
         sync <- Changeset.apply_changes(sync_changeset),
         multi <- Multi.new(),
         :ok <- BotState.set_sync_status("syncing"),
         {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_0()),
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
