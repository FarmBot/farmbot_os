defmodule FarmbotOS.Platform.Target.InfoWorker.WifiLevel do
  use GenServer
  alias FarmbotCore.{Config, BotState}
  import FarmbotOS.Platform.Target.Network.Utils

  @checkup_time_ms 15_000
  @error_time_ms 60_000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    ifname = Keyword.fetch!(args, :ifname)
    {:ok, ifname, 0}
  end

  def handle_info(:timeout, ifname) do
    case Config.Repo.get_by(Config.NetworkInterface, name: ifname) do
      nil ->
        {:noreply, ifname, @error_time_ms}

      %{ssid: ssid} ->
        do_check_level(ssid, ifname)
    end
  end

  def do_check_level(ssid, ifname) do
    scan(ifname)
    |> Enum.find(fn %{ssid: scanned} ->
      scanned == ssid
    end)
    |> case do
      nil ->
        {:noreply, ifname, @error_time_ms}

      %{level: level} ->
        BotState.report_wifi_level(level)
        {:noreply, ifname, @checkup_time_ms}
    end
  end
end
