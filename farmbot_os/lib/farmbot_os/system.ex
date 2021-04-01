defmodule FarmbotOS.System do
  @moduledoc """
  Common functionality that should be implemented by a system
  """
  require FarmbotCore.Logger
  require Logger
  alias FarmbotCore.Asset

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

    Logger.info("Stopping app: :farmbot_ext")
    _ = Application.stop(:farmbot_ext)

    Logger.info("Stopping app: :farmbot_core")
    _ = Application.stop(:farmbot_core)

    Logger.info("Starting ap: :farmbot_core")
    _ = Application.ensure_all_started(:farmbot_core)

    Logger.info("Starting ap: :farmbot_ext")
    _ = Application.ensure_all_started(:farmbot_ext)

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
  def factory_reset(reason, force \\ false) do
    if force || should_factory_reset?() do
      try_lock_fw()
      set_shutdown_reason(reason)
      _ = FarmbotCore.EctoMigrator.drop()
      reboot(reason)
      :ok
    else
      FarmbotCore.Logger.error(1, "Factory Reset disabled.")
      :ok
    end
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
    FarmbotCore.Logger.debug(3, "power down event: #{inspect(reason)}")
    file = FarmbotOS.FileSystem.shutdown_reason_path()
    if reason, do: File.write!(file, inspect(reason)), else: File.rm_rf(file)
  end

  # Check if the FarmbotCore.Firmware process is alive
  def try_lock_fw(fw_module \\ FarmbotCore.Firmware) do
    try do
      if Process.whereis(fw_module) do
        FarmbotCore.Logger.warn(1, "Emergency locking and powering down")
        fw_module.command({:command_emergency_lock, []})
      else
        FarmbotCore.Logger.error(1, "Emergency lock failed. Powering down (1)")
      end
    rescue
      _ ->
        FarmbotCore.Logger.error(1, "Emergency lock failed. Powering down (2)")
    end
  end

  # This is wrapped in a try/catch because it's possible that
  # the `Asset.Repo` server is not running. We want to ensure if it isn't
  # Running, we are still able to reset.
  defp should_factory_reset? do
    try do
      if Asset.fbos_config(:disable_factory_reset), do: false, else: true
    catch
      _, _ -> true
    end
  end
end
