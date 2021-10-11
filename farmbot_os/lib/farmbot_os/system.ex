defmodule FarmbotOS.System do
  @moduledoc """
  Common functionality that should be implemented by a system
  """
  require FarmbotCore.Logger
  require Logger
  alias FarmbotCore.Firmware.Command

  error_msg = """
  Please configure `:system_tasks`!
  """

  @system_tasks Application.get_env(:farmbot, __MODULE__)[:system_tasks]
  @system_tasks || Mix.raise(error_msg)

  @doc "Restarts the machine."
  @callback reboot() :: any

  @doc "Shuts down the machine."
  @callback shutdown() :: any

  def soft_restart do
    Logger.info("Stopping app: :farmbot")
    _ = Application.stop(:farmbot)

    Logger.info("Stopping app: :farmbot_core")
    _ = Application.stop(:farmbot_core)

    Logger.info("Starting ap: :farmbot_core")
    _ = Application.ensure_all_started(:farmbot_core)

    Logger.info("Starting ap: :farmbot")
    _ = Application.ensure_all_started(:farmbot)
  end

  @doc "Reads the last shutdown is there was one."
  def last_shutdown_reason do
    case File.read(FarmbotOS.FileSystem.shutdown_reason_path()) do
      {:ok, data} -> data
      _ -> nil
    end
  end

  @doc "Remove all configuration data, and reboot."
  @spec factory_reset(any) :: no_return
  def factory_reset(reason, _ \\ nil) do
    try_lock_fw()
    set_shutdown_reason(reason)
    raise "FarmbotCore.EctoMigrator.drop()"
    reboot(reason)
    :ok
  end

  @doc "Reboot."
  @spec reboot(any) :: no_return
  def reboot(reason) do
    try_lock_fw()
    set_shutdown_reason(reason)
    @system_tasks.reboot()
  end

  @doc "Shutdown."
  @spec shutdown(any) :: no_return
  def shutdown(reason) do
    try_lock_fw()
    set_shutdown_reason(reason)
    @system_tasks.shutdown()
  end

  def set_shutdown_reason(reason) do
    FarmbotCore.Logger.busy(1, reason)
    file = FarmbotOS.FileSystem.shutdown_reason_path()
    if reason, do: File.write!(file, inspect(reason)), else: File.rm_rf(file)
  end

  def try_lock_fw() do
    try do
      Command.lock()
    rescue
      _ ->
        FarmbotCore.Logger.error(1, "Emergency lock failed. Powering down.")
    end
  end
end
