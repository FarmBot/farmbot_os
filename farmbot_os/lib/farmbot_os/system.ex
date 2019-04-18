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

  @data_path FarmbotOS.FileSystem.data_path()

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
    file = Path.join(@data_path, "last_shutdown_reason")

    case File.read(file) do
      {:ok, data} -> data
      _ -> nil
    end
  end

  @doc "Remove all configuration data, and reboot."
  @spec factory_reset(any) :: no_return
  def factory_reset(reason, force \\ false) do
    if force || should_factory_reset?() do
      try_lock_fw()
      write_file(reason)
      _ = FarmbotCore.EctoMigrator.drop()
      _ = Supervisor.start_child(:elixir_sup, {Task, &FarmbotOS.System.soft_restart/0})
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
    write_file(reason)
    @system_tasks.reboot()
  end

  @doc "Shutdown."
  @spec shutdown(any) :: no_return
  def shutdown(reason) do
    try_lock_fw()
    write_file(reason)
    @system_tasks.shutdown()
  end

  defp write_file(reason) do
    file = Path.join(@data_path, "last_shutdown_reason")
    if reason, do: File.write!(file, inspect(reason)), else: File.rm_rf(file)
  end

  # Check if the FarmbotFirmware process is alive
  defp try_lock_fw do
    if Process.whereis(FarmbotFirmware) do
      FarmbotCore.Logger.warn(1, "Trying to emergency lock firmware before powerdown")
      FarmbotFirmware.command({:command_emergency_lock, []})
    else
      FarmbotCore.Logger.error(1, "Firmware unavailable. Can't emergency_lock")
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
