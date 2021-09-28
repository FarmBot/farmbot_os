defmodule FarmbotOS.SysCalls do
  @moduledoc """
  Implementation for FarmbotCore.Celery.SysCalls
  """

  require FarmbotCore.Logger
  require FarmbotTelemetry
  require Logger

  alias FarmbotCore.Celery.AST
  alias FarmbotCore.Asset
  alias FarmbotCore.BotState
  alias FarmbotCore.Leds
  alias FarmbotExt.API
  alias FarmbotOS.Lua

  alias FarmbotCore.Asset.{
    BoxLed,
    Private,
    Sync
  }

  alias FarmbotCore.Firmware.{
    Command,
    UARTCore
  }

  alias FarmbotExt.API.{
    Reconciler,
    SyncGroup
  }

  alias FarmbotOS.SysCalls.{
    ChangeOwnership,
    CheckUpdate,
    FactoryReset,
    Farmware,
    Movement,
    PinControl,
    PointLookup,
    ResourceUpdate,
    SendMessage,
    SetPinIOMode
  }

  @behaviour FarmbotCore.Celery.SysCalls

  @impl true
  defdelegate send_message(level, message, channels), to: SendMessage

  @impl true
  defdelegate execute_script(name, env), to: Farmware

  @impl true
  defdelegate update_farmware(name), to: Farmware

  @impl true
  defdelegate flash_firmware(package), to: UARTCore

  @impl true
  defdelegate change_ownership(email, secret, server), to: ChangeOwnership

  @impl true
  defdelegate check_update(), to: CheckUpdate

  @impl true
  defdelegate read_status(), to: FarmbotExt.MQTT.BotStateHandler

  @impl true
  defdelegate factory_reset(package), to: FactoryReset

  @impl true
  defdelegate set_pin_io_mode(pin, mode), to: SetPinIOMode

  @impl true
  defdelegate perform_lua(expression, extra_vars, comment), to: Lua

  defdelegate log_assertion(passed?, type, message), to: Lua

  @impl true
  defdelegate read_pin(number, mode), to: PinControl

  @impl true
  defdelegate read_cached_pin(number), to: PinControl

  @impl true
  defdelegate write_pin(number, mode, value), to: PinControl

  @impl true
  defdelegate toggle_pin(number), to: PinControl

  @impl true
  defdelegate set_servo_angle(pin, angle), to: PinControl

  @impl true
  defdelegate update_resource(kind, id, params), to: ResourceUpdate

  @impl true
  defdelegate get_current_x(), to: Movement

  @impl true
  defdelegate get_current_y(), to: Movement

  @impl true
  defdelegate get_current_z(), to: Movement

  @impl true
  defdelegate get_cached_x(), to: Movement

  @impl true
  defdelegate get_cached_y(), to: Movement

  @impl true
  defdelegate get_cached_z(), to: Movement

  @impl true
  defdelegate zero(axis), to: Movement

  defdelegate get_position(), to: Movement

  defdelegate get_position(axis), to: Movement

  defdelegate get_cached_position(), to: Movement

  defdelegate get_cached_position(axis), to: Movement

  @impl true
  defdelegate move_absolute(x, y, z, speed), to: Movement

  @impl true
  defdelegate move_absolute(x, y, z, sx, sy, sz), to: Movement

  @impl true
  defdelegate calibrate(axis), to: Movement

  @impl true
  defdelegate find_home(axis), to: Movement

  @impl true
  defdelegate home(axis, speed), to: Movement

  @impl true
  defdelegate point(kind, id), to: PointLookup

  @impl true
  defdelegate find_points_via_group(id), to: Asset

  @impl true
  defdelegate get_toolslot_for_tool(id), to: PointLookup

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
    FarmbotOS.System.reboot("Rebooting...")
    :ok
  end

  @impl true
  def power_off do
    FarmbotOS.System.shutdown("Shutting down...")
    :ok
  end

  @impl true
  def firmware_reboot do
    FarmbotCore.Firmware.UARTCore.restart_firmware()
    :ok
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
  def emergency_lock do
    Command.lock()
    FarmbotCore.Logger.error(1, "E-stopped")
    FarmbotCore.FirmwareEstopTimer.start_timer()
    Leds.red(:off)
    Leds.yellow(:slow_blink)
    :ok
  end

  @impl true
  def emergency_unlock do
    Command.unlock()
    FarmbotCore.Logger.busy(1, "Unlocked")
    Leds.yellow(:off)
    Leds.red(:solid)
    :ok
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
  def sync() do
    FarmbotCore.Logger.busy(3, "Syncing")

    with {:ok, sync_changeset} <- API.get_changeset(Sync),
         :ok <- BotState.set_sync_status("syncing"),
         _ <- Leds.green(:really_fast_blink),
         sync_changeset <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_0()),
         sync_changeset <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_1()),
         sync_changeset <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_2()),
         sync_changeset <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_3()),
         _sync_changeset <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_4()) do
      FarmbotCore.Logger.success(3, "Synced")
      :ok = BotState.set_sync_status("synced")
      _ = Leds.green(:solid)

      :ok
    else
      error ->
        FarmbotTelemetry.event(:asset_sync, :sync_error, nil,
          error: inspect(error)
        )

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
  def install_first_party_farmware() do
    {:error, "install_first_party_farmware not yet supported"}
  end

  @impl true
  def nothing(), do: nil

  def give_firmware_reason(where, reason) do
    w = inspect(where)
    r = inspect(reason)
    {:error, "Firmware error @ #{w}: #{r}"}
  end

  @impl true
  def fbos_config() do
    conf = FarmbotCore.Asset.fbos_config()
    output = FarmbotCore.Asset.FbosConfig.render(conf)
    {:ok, output}
  end
end
