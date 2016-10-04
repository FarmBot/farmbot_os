defmodule Fw do
  require Logger
  use Supervisor
  @target System.get_env("NERVES_TARGET") || "rpi3"
  @version Path.join(__DIR__ <> "/..", "VERSION")
    |> File.read!
    |> String.strip

  def init(_args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, MyRouter, [], [port: 4000]),
      supervisor(NetworkSupervisor, [[]], restart: :permanent),
      supervisor(Controller, [[]], restart: :permanent)
    ]
    opts = [strategy: :one_for_all, name: Fw]
    supervise(children, opts)
  end

  def start(_type, args) do
    Logger.debug("Starting Firmware on Target: #{@target}")
    Supervisor.start_link(__MODULE__, args)
  end

  def version do
    @version
  end

  def factory_reset do
    File.rm("/root/secretes.txt")
    File.rm("/root/network.config")
    Nerves.Firmware.reboot
  end
end
