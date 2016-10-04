defmodule NetworkSupervisor do
  require Logger
  use Supervisor
  @env Mix.env
  def start_link(_args) do
    Logger.debug("Starting Network")
    Nerves.Networking.setup(:eth0) # eh
    children = [ worker(Wifi, [[]]) ]
    opts = [strategy: :one_for_all, name: NetworkSupervisor]
    Supervisor.start_link(children, opts)
  end

  def set_time do
    case @env do
      :prod ->
        Logger.debug("Setting time. If it seems to hang here, reboot. Need a better ntp pool.")
        System.cmd("ntpd", ["-q",
         "-p", "0.pool.ntp.org",
         "-p", "1.pool.ntp.org",
         "-p", "2.pool.ntp.org",
         "-p", "3.pool.ntp.org"])
        check_time_set
        Logger.debug("Time set.")
        :ok
      _ -> :ok
    end
  end

  def check_time_set do
    if :os.system_time(:seconds) <  1474929 do
      check_time_set # wait until time is set
    end
  end
end
