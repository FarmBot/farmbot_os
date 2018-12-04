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
    r = block_check(true)
    {:ok, %{timer: start_timer(), last_result: r}}
  end

  def handle_info(:checkup, state) do
    # Block and don't reset if after 10 tries
    # resolution doesn't work.
    result = block_check(state.last_result)
    {:noreply, %{state | last_result: result, timer: start_timer()}}
  end

  defp block_check(last_result, reset \\ false, tries \\ 10)

  defp block_check(last_result, false, 0) do
    server = get_config_value(:string, "authorization", "server")
    if last_result == :ok do
      Logger.error 1, "Could not resolve #{server} after 10 tries."
    end
    :error
  end

  defp block_check(_last_result, true, 0) do
    server = get_config_value(:string, "authorization", "server")
    Logger.error 1, "Tried 10 times to resolve DNS requests."
    msg = """
    FarmBot is unable to make DNS requests to #{server} after
    10 tries. It is possible your network has a firewall blocking this
    url, or your FarmBot is configured incorrectly.
    """
    Farmbot.System.factory_reset(msg)
    :error
  end

  defp block_check(last_result, reset, tries) do
    server = get_config_value(:string, "authorization", "server")
    case test_dns() do
      {:ok, _} ->
        if last_result == :error do
          Logger.success(1, "DNS resolution successful")
        end
        :ok
      {:error, :nxdomain} ->
        Process.sleep(10_000)
        if last_result == :ok do
          Logger.error 1, "Trying to resolve #{server} #{tries - 1} more times."
        end
        block_check(:error, reset, tries - 1)
      err ->
        if last_result == :ok do
          Logger.error 1, "Failed to resolve #{server}: #{inspect err}"
        end
        block_check(:error, reset, tries)
    end
  end

  defp start_timer do
    Process.send_after(self(), :checkup, 45_000)
  end
end
