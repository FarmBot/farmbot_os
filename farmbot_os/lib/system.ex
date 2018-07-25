defmodule Farmbot.System do
  @moduledoc """
  Common functionality that should be implemented by a system
  """

  require Farmbot.Logger

  error_msg = """
  Please configure `:system_tasks` and `:data_path`!
  """

  @system_tasks Application.get_env(:farmbot_os, :behaviour)[:system_tasks]
  @system_tasks || Mix.raise(error_msg)

  @data_path Application.get_env(:farmbot_ext, :data_path)
  @data_path || Mix.raise(error_msg)

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
    if Process.whereis(Farmbot.Firmware) do
      Farmbot.Logger.warn 1, "Trying to emergency lock firmware before powerdown"
      Farmbot.Firmware.emergency_lock()
    else
      Farmbot.Logger.error 1, "Firmware unavailable. Can't emergency_lock"
    end
  end

  @doc "Remove all configuration data, and reboot."
  @spec factory_reset(any) :: no_return
  def factory_reset(reason) do
    if Farmbot.Project.env == :dev do
      # credo:disable-for-next-line
      require IEx; IEx.pry()
    end
    alias Farmbot.Config
    import Config, only: [get_config_value: 3]
    if Process.whereis Farmbot.Core do
      if get_config_value(:bool, "settings", "disable_factory_reset") do
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
    Farmbot.BootState.write(:NEEDS_CONFIGURATION)
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
    IO.puts "Farmbot powering down: #{reason}"
    file = Path.join(@data_path, "last_shutdown_reason")
    File.write!(file, inspect(reason))
  end
end
