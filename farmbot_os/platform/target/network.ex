defmodule FarmbotOS.Platform.Target.Network do
  @moduledoc "Manages Network Connections"
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(_args) do
    send(self(), :setup)
    {:ok, %{}}
  end

  @impl GenServer
  def handle_info(:setup, state) do
    case VintageNet.get_configuration("wlan0") do
    end
  end
end
