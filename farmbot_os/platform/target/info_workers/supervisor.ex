defmodule FarmbotOS.Platform.Target.InfoWorker.Supervisor do
  @moduledoc false
  use Supervisor

  alias FarmbotOS.Platform.Target.InfoWorker.{
    DiskUsage,
    MemoryUsage,
    SocTemp,
    Throttle,
    Uptime,
    WifiLevel
  }

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    children = [
      DiskUsage,
      MemoryUsage,
      SocTemp,
      Throttle,
      Uptime,
      {WifiLevel, ifname: "wlan0"}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
