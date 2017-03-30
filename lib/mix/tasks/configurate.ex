defmodule Mix.Tasks.Farmbot.Configurate do
  @moduledoc false
  use Mix.Task
  alias HTTPoison, as: HTTP

  def run([ip_addr]) do
    System.put_env("IPADDR", ip_addr)
    IEx.Helpers.recompile
    Mix.shell.info([:green, "Going to configurate: #{ip_addr}"])
    {:ok, _} = HTTP.start
    case HTTP.get(ip_addr <> "/api/ping") do
      {:ok, _resp} -> start_config(ip_addr)
      _ -> Mix.raise "Could not connect to bot!"
    end
  end

  def start_config(ip) do
    config = HTTP.get!(ip <> "/api/config") |> parse_http
    {server, user, pass} = configure_auth_creds()
    auth = %{"server" => server}

    network = configure_network(config["network"], ip)

    config = %{config | "authorization" => auth, "network" => network}
    auth_payload = %{pass: pass, email: user, server: server} |> Poison.encode!

    Mix.shell.info "Posting credentials"
    %{status_code: 200} = HTTP.post!(ip <> "/api/config/creds", auth_payload, headers())

    Mix.shell.info "Posting config file"
    %{status_code: 200} = HTTP.post!(ip <> "/api/config", Poison.encode!(config), headers())

    Mix.shell.info "Trying to log in."
    %{status_code: 200} = HTTP.post!(ip <> "/api/try_log_in", "", headers())
  end

  def configure_auth_creds do
    server = IO.gets """
    Please enter your API server (localhost:3000):
    """
    server = server |> parse_server
    IO.puts("\n")

    user = IO.gets """
    Please enter your API username (admin@admin.com):
    """
    user = user |> parse_user
    IO.puts("\n")

    pass = IO.gets """
    Please enter your API password (password123):
    """
    pass = pass |> parse_pass
    IO.puts("\n")

    {server, user, pass}
  end

  def configure_network(false), do: false
  def configure_network(%{"interfaces" => ifaces} = netconfig, ip) do
    blerp = Enum.map(ifaces, fn({iface, config}) ->
      configure_iface(iface, config, ip)
    end)

    %{netconfig | "interfaces" => Map.new(blerp)}
  end

  defp configure_iface(iface, %{"type" => "wired"} = eth_config, _ip) do
    use_iface = IO.gets """
    Use ethernet device #{iface} (N/y):
    """

    use_iface = parse_yn(use_iface, false)
    if use_iface do
      {iface, %{eth_config | "default" => "dhcp"}}
    else
      # if we dont want to use ethernet
      {iface, eth_config}
    end
  end

  defp configure_iface(iface, %{"type" => "wireless"} = w_config, ip) do
    use_iface = IO.gets """
    Use Wireless device #{iface} (n/Y):
    """

    use_iface = parse_yn(use_iface, true)
    if use_iface do
      scan = IO.gets """
      Scan for wireless access points? (n/Y)
      """
      scan = parse_yn(scan, true)
      ssid = select_ssid(scan, iface, ip)
      psk = get_psk()
      settings = %{"ssid" => ssid, "psk" => psk, "key_mgmt" => "WPA-PSK"}
      {iface, %{w_config | "default" => "dhcp", "settings" => settings}}
    else
      # if we dont want to use wireless
      {iface, w_config}
    end
  end

  defp get_psk do
    thing = IO.gets """
    Enter the psk for this access point:
    """
    String.trim(thing)
  end

  # if this is true, scan
  defp select_ssid(true, iface, ip) do
    payload = %{"iface" => iface} |> Poison.encode!
    list = HTTP.post!(ip <> "/api/network/scan", payload, headers()) |> parse_http

    # %{1 => "ssid1", 2 => "ssidblerp"}
    {ssid_index_list, _} = Enum.reduce(list, {[], 0}, fn(ssid, {acc, count}) ->
      {[{count, ssid} | acc], count + 1}
    end)

    ssid_index_map = Map.new(ssid_index_list)

    ssid_list_txt = Enum.reduce(ssid_index_map, "", fn({index, ssid}, acc) ->
      "[#{index}] => #{ssid}\n" <> acc
    end)

    ssid_index = IO.gets """
    #{ssid_list_txt}
    Enter the number of the ssid you want to use:
    """
    ssid_index = parse_integer(ssid_index)
    ssid_index_map[ssid_index]
  end

  # if no scan, make the user enter it manually.
  defp select_ssid(_bool, _iface, _ip) do
    ssid = IO.gets """
    Enter the wireless access point you want to connect to:
    """
    String.trim(ssid)
  end

  defp headers do
    [{"Content-Type", "application/json"}]
  end

  defp parse_http(%{body: body}), do: Poison.decode!(body)

  defp parse_integer(str) do
    str
    |> String.trim()
    |> String.to_integer
  end

  defp parse_yn(resp, default)
  defp parse_yn("\n", bool), do: bool
  defp parse_yn("Y\n", _), do: true
  defp parse_yn("y\n", _), do: true
  defp parse_yn("yes\n", _), do: true

  defp parse_yn("N\n", _), do: false
  defp parse_yn("n\n", _), do: false
  defp parse_yn("no\n", _), do: false

  defp parse_server("staging\n"), do: "https://staging.farmbot.io"
  defp parse_server("prod\n"), do: "https://my.farmbot.io"
  defp parse_server("\n"), do: "http://localhost:3000"
  defp parse_server(server), do: String.trim(server)

  defp parse_user("\n"), do: "admin@admin.com"
  defp parse_user(user), do: String.trim(user)

  defp parse_pass("\n"), do: "password123"
  defp parse_pass(pass), do: String.trim(pass)
end
