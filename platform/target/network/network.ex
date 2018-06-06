defmodule Farmbot.Target.Network do
  @moduledoc "Bring up network."

  @behaviour Farmbot.System.Init
  alias Farmbot.System.ConfigStorage
  import ConfigStorage, only: [get_config_value: 3]
  alias ConfigStorage.NetworkInterface
  alias Farmbot.Target.Network.Manager, as: NetworkManager
  alias Farmbot.Target.Network.ScanResult

  use Supervisor
  use Farmbot.Logger

  @doc "List available interfaces. Removes unusable entries."
  def get_interfaces(tries \\ 5)
  def get_interfaces(0), do: []
  def get_interfaces(tries) do
    case Nerves.NetworkInterface.interfaces() do
      ["lo"] ->
        Process.sleep(100)
        get_interfaces(tries - 1)
      interfaces when is_list(interfaces) ->
        interfaces
        |> List.delete("usb0") # Delete unusable entries if they exist.
        |> List.delete("lo")
        |> List.delete("sit0")
        |> Map.new(fn(interface) ->
          {:ok, settings} = Nerves.NetworkInterface.status(interface)
          {interface, settings}
        end)
    end
  end

  @doc "Scan on an interface."
  def scan(iface, tries \\ 5)

  def scan(iface, 0) do
    Logger.warn(1, "Tried scanning on #{iface} 5 times, with no results each time.")
    []
  end

  def scan(iface, tries) do
    do_scan(iface)
    |> ScanResult.decode()
    |> ScanResult.sort_results()
    |> ScanResult.decode_security()
    |> Enum.filter(&Map.get(&1, :ssid))
    |> Enum.map(&Map.update(&1, :ssid, nil, fn(ssid) -> to_string(ssid) end))
    |> Enum.reject(&String.contains?(&1.ssid, "\\x00"))
    |> Enum.uniq_by(fn(%{ssid: ssid}) -> ssid end)
    |> case do
      [] -> scan(iface, tries - 1)
      data -> data
    end
  end

  # While scanning in AP mode, The CTRL-EVENT-SCAN-COMPLETE event never happens.
  defp wait_for_scan_results(pid, timer, count, loops_without_change, acc)
  defp wait_for_scan_results(_pid, _timer, _count, 10, acc), do: acc
  defp wait_for_scan_results(pid, timer, count, loops_without_change, acc) do
    res = Nerves.WpaSupplicant.request(pid, {:BSS, count})
    new_acc = if res, do: [res | acc], else: acc
    new_count = if res, do: count + 1, else: count
    new_loops_without_change = if res, do: 0, else: loops_without_change + 1

    receive do
      :complete -> acc
      {Nerves.WpaSupplicant, {:"CTRL-EVENT-BSS-REMOVED", _, _}, _} ->
        Process.cancel_timer(timer)
        wait_for_scan_results(pid, Process.send_after(self(), :complete, 5000), 0, 0, [])
      _ -> wait_for_scan_results(pid, timer, new_count, new_loops_without_change, new_acc)
    after 10 -> wait_for_scan_results(pid, timer, new_count, new_loops_without_change, new_acc)
    end
  end

  def do_scan(iface) do
    pid = :"Nerves.WpaSupplicant.#{iface}"
    Elixir.Registry.register(Nerves.WpaSupplicant, iface, [])
    case Nerves.WpaSupplicant.request(pid, :SCAN) do
      r when r in ["FAIL-BUSY", :ok] ->
        results = wait_for_scan_results(pid, Process.send_after(self(), :complete, 5000), 0, 0, [])
        Elixir.Registry.unregister(Nerves.WpaSupplicant, iface)
        results
      resp -> raise("Unexpected scan result: #{inspect resp}")
    end
  end

  @doc "Tests if we can make dns queries."
  def test_dns(hostname \\ nil)

  def test_dns(nil) do
    case get_config_value(:string, "authorization", "server") do
      nil -> 'nerves-project.org'
      <<"https://" <> host :: binary>> -> test_dns(to_charlist(host))
      <<"http://"  <> host :: binary>> -> test_dns(to_charlist(host))
    end
  end

  def test_dns(hostname) do
    :inet_res.gethostbyname(hostname)
  end

  # TODO Expand this to allow for more settings.
  def to_network_config(config)

  def to_network_config(%NetworkInterface{type: "wireless"} = config) do
    Logger.debug(3, "wireless network config: ssid: #{config.ssid}")
    opts = [ssid: config.ssid, key_mgmt: config.security]
    case config.security do
      "WPA-PSK" ->
        {config.name, Keyword.merge(opts, [psk: config.psk])} |> maybe_use_advanced(config)
      "NONE" ->
        {config.name, opts} |> maybe_use_advanced(config)
      other -> raise "Unsupported wireless security type: #{other}"
    end
  end

  def to_network_config(%NetworkInterface{type: "wired"} = config) do
    {config.name, []} |> maybe_use_advanced(config)
  end

  defp maybe_use_advanced({name, opts}, config) do
    case config.ipv4_method do
      "static" ->
        settings = [ipv4_method: "static", ipv4_address: config.ipv4_address, ipv4_gateway: config.ipv4_gateway, ipv4_subnet_mask: config.ipv4_subnet_mask]
        {name, Keyword.merge(opts, settings)}
      "dhcp" -> {name, opts}
    end
    |> maybe_use_name_servers(config)
    |> maybe_use_domain(config)
  end

  defp maybe_use_name_servers({name, opts}, config) do
    if config.name_servers do
      {name, Keyword.put(opts, :name_servers, String.split(config.name_servers, " "))}
    else
      {name, opts}
    end
  end

  defp maybe_use_domain({name, opts}, config) do
    if config.domain do
      {name, Keyword.put(opts, :domain, config.domain)}
    else
      {name, opts}
    end
  end

  def to_child_spec({interface, opts}) do
    worker(NetworkManager, [interface, opts])
  end

  def start_link(_, opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    config = ConfigStorage.get_all_network_configs()
    Logger.info(3, "Starting Networking")
    children = config
      |> Enum.map(&to_network_config/1)
      |> Enum.map(&to_child_spec/1)
      |> Enum.uniq() # Don't know why/if we need this?
    supervise(children, strategy: :one_for_one)
  end
end
