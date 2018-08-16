defmodule Farmbot.Target.Network.DnsTask do
  use Farmbot.Logger
  use GenServer
  import Farmbot.Target.Network, only: [test_dns: 0]
  import Farmbot.System.ConfigStorage, only: [get_config_value: 3]

  def start_link(args, opts) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init([]) do
    # Block and reset if after 10 tries
    # resolution doesn't  work.
    block_check(true)
    {:ok, %{timer: start_timer()}}
  end

  def handle_info(:checkup, state) do
    # Block and don't reset if after 10 tries
    # resolution doesn't work.
    block_check()
    {:noreply, %{state | timer: start_timer()}}
  end

  defp block_check(reset \\ false, tries \\ 10)

  defp block_check(false, 0) do
    server = get_config_value(:string, "authorization", "server")
    Logger.error 1, "Could not resolve #{server} after 10 tries."
  end

  defp block_check(true, 0) do
    server = get_config_value(:string, "authorization", "server")
    Logger.error 1, "Tried 10 times to resolve DNS requests."
    msg = """
    FarmBot is unable to make DNS requests to #{server} after
    10 tries. It is possible your network has a firewall blocking this
    url, or your FarmBot is configured incorrectly.
    """
    Farmbot.System.factory_reset(msg)
  end

  defp block_check(reset, tries) do
    server = get_config_value(:string, "authorization", "server")
    case test_dns() do
      {:ok, _} -> :ok
      {:error, :nxdomain} ->
        Process.sleep(10_000)
        Logger.error 1, "Trying to resolve #{server} #{tries - 1} more times."
        block_check(reset, tries - 1)
      err ->
        Logger.error 1, "Failed to resolve #{server}: #{inspect err}"
        block_check(reset, tries)
    end
  end

  defp start_timer do
    Process.send_after(self(), :checkup, 45_000)
  end
end
