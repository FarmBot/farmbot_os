defmodule FarmbotOS.System do
  @moduledoc """
  Common functionality that should be implemented by a system
  """
  require FarmbotCore.Logger
  alias FarmbotCore.{Asset, Project}

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

  @doc "Reads the last shutdown is there was one."
  def last_shutdown_reason do
    file = Path.join(@data_path, "last_shutdown_reason")

    case File.read(file) do
      {:ok, data} -> data
      _ -> nil
    end
  end

  defp try_lock_fw do
    if Process.whereis(FarmbotFirmware) do
      FarmbotCore.Logger.warn(1, "Trying to emergency lock firmware before powerdown")
      FarmbotFirmware.command({:command_emergency_lock, []})
    else
      FarmbotCore.Logger.error(1, "Firmware unavailable. Can't emergency_lock")
    end
  end

  @doc "Remove all configuration data, and reboot."
  @spec factory_reset(any) :: no_return
  def factory_reset(reason) do
    if Project.env() == :dev do
      # credo:disable-for-next-line
      require IEx
      IEx.pry()
    end

    if Process.whereis(FarmbotCore) do
      if Asset.fbos_config().disable_factory_reset do
        reboot(reason)
      else
        do_reset(reason)
      end
    else
      do_reset(reason)
    end
  end

  defp do_reset(reason) do
    Application.stop(:farmbot_ext)
    Application.stop(:farmbot_core)

    for p <- Path.wildcard(Path.join(@data_path, "*")) do
      File.rm_rf!(p)
    end

    reboot(reason)
  end

  @doc "Reboot."
  @spec reboot(any) :: no_return
  def reboot(reason) do
    write_file(reason)
    try_lock_fw()
    @system_tasks.reboot()
  end

  @doc "Shutdown."
  @spec shutdown(any) :: no_return
  def shutdown(reason) do
    write_file(reason)
    try_lock_fw()
    @system_tasks.shutdown()
  end

  defp write_file(nil) do
    file = Path.join(@data_path, "last_shutdown_reason")
    File.rm_rf(file)
  end

  defp write_file(reason) do
    IO.puts("Farmbot powering down: #{reason}")
    file = Path.join(@data_path, "last_shutdown_reason")
    File.write!(file, inspect(reason))
  end
end
