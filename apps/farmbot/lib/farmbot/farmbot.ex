defmodule Farmbot do
  @moduledoc """
    Main entry point to the application.
    Basically just starts some supervisors.
  """
  require Logger
  use Supervisor
  alias Farmbot.Sync.Database
  alias Nerves.Firmware
  alias Farmbot.Supervisor, as: FarmbotSupervisor

  @doc """
    Shortcut to Nerves.Firmware.reboot
  """
  @spec reboot :: any
  def reboot do
    Logger.warn ">> going down for a reboot!"
    Firmware.reboot
  end

  @doc """
    Shortcut to Nerves.Firmware.poweroff
  """
  @spec reboot :: any
  def poweroff do
    Logger.warn ">> going to power down!"
    Firmware.poweroff
  end

  def init([%{target: target, compat_version: compat_version,
                      version: version, env: env}])
  do
    children = [
      worker(Farmbot.Network, [target], [restart: :permanent]),
      supervisor(FarmbotSupervisor,
                [%{target: target,
                   compat_version: compat_version,
                   version: version,
                   env: env}],
                restart: :permanent)
    ]
    opts = [strategy: :one_for_one, name: Farmbot]
    supervise(children, opts)
  end

  def start(_type, [%{target: target, compat_version: compat_version,
                      version: version, env: env}])
  do
    Logger.debug ">> is booting on #{target}."
    Amnesia.start
    Database.create! Keyword.put([], :memory, [node])
    Database.wait(15_000)

    Supervisor.start_link(__MODULE__,
          [%{target: target, compat_version: compat_version,
             version: version, env: env}])
  end
  @lint false
  @doc """
    Factory Resets your Farmbot.
  """
  def factory_reset, do: Farmbot.FileSystem.factory_reset
end
