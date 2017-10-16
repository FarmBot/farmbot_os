defmodule Farmbot.Target.Network do
  @moduledoc "Bring up network."

  @behaviour Farmbot.System.Init
  alias Farmbot.System.ConfigStorage
  alias ConfigStorage.NetworkInterface
  use Supervisor
  require Logger

  def test_dns(hostname \\ 'nerves-project.org') do
    :inet_res.gethostbyname(hostname)
  end

  def start_link(_, opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    config = ConfigStorage.all NetworkInterface
    Logger.info "Starting Networking: #{inspect config}"
    require IEx; IEx.pry
  end
end
