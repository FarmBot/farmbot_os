defmodule FarmbotOS.Platform.Target.InfoWorker.Supervisor do
  @moduledoc """
  Supervisor responsible for monitoring info workers
  """

  use Supervisor

  alias FarmbotOS.Platform.Target.InfoWorker.{
    DiskUsage,
    MemoryUsage,
    SocTemp,
    Throttle,
    VideoDevices,
    Uptime,
    WifiLevel
  }

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Supervisor
  def init([]) do
    children = [
      DiskUsage,
      MemoryUsage,
      SocTemp,
      Throttle,
      VideoDevices,
      Uptime,
      {WifiLevel, ifname: "wlan0"}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
