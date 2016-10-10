defmodule NetworkSupervisor do
  require Logger
  use Supervisor
  @env Mix.env

  def init(_args) do
    # Nerves.Networking.setup(:eth0) # eh
    children = [ worker(Wifi, [[]]) ]
    opts = [strategy: :one_for_all, name: __MODULE__]
    supervise(children, opts)
  end

  def start_link(args) do
    Logger.debug("Starting Network")
    Supervisor.start_link(__MODULE__, args)
  end

  def set_time do
    case @env do
      :prod ->
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
