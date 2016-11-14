defmodule Fw do
  require Logger
  use Supervisor
  @state_path Application.get_env(:fb, :state_path)

  @doc """
    Shortcut to Nerves.Firmware.reboot
  """
  def reboot do
    Nerves.Firmware.reboot
  end


  @doc """
    Shortcut to Nerves.Firmware.poweroff
  """
  def poweroff do
    Nerves.Firmware.poweroff
  end

  @doc """
    Formats the sytem partition, and mounts as read/write
  """
  def format_state_part do
    Logger.warn("FORMATTING DATA PARTITION!")
    System.cmd("mkfs.ext4", ["/dev/mmcblk0p3", "-F"])
    System.cmd("mount", ["/dev/mmcblk0p3", "/state", "-t", "ext4"])
    File.write("/state/.formatted", "DONT CAT ME\n")
  end

  @doc """
    Checks for a .formatted file on the state/data partition, if it doesnt exit
    it formats the partition
  """
  def fs_init(:prod) do
    with {:error, :enoent} <- File.read("#{@state_path}/.formatted") do
      format_state_part
    end
  end

  def fs_init(_) do
    {:ok, :development}
  end

  def init([%{target: target, compat_version: compat_version, version: version, env: env}]) do
    children = [
      # Storage that needs to persist across reboots.
      worker(SafeStorage, [env], restart: :permanent),

      # master state tracker.
      worker(BotState, [%{target: target, compat_version: compat_version, version: version, env: env}], restart: :permanent),

      # something sarcastic
      worker(SSH, [env], restart: :permanent),

      # Main controller stuff.
      supervisor(Controller, [[]], restart: :permanent)
    ]
    opts = [strategy: :one_for_one, name: Fw]
    supervise(children, opts)
  end

  def start(_type, [%{target: target, compat_version: compat_version, version: version, env: env}]) do
    {:ok, _} = fs_init(env)
    Logger.debug("Starting Firmware on Target: #{target}")
    Supervisor.start_link(__MODULE__, [%{target: target, compat_version: compat_version, version: version, env: env}])
  end

  def factory_reset do
    GenServer.stop SafeStorage, :reset
    Nerves.Firmware.reboot
  end
end
