defmodule Farmbot.Target.Bootstrap.Configurator.Router do
  @moduledoc "Routes web connections."

  use Plug.Router

  if Mix.env == :dev do
    use Plug.Debugger, otp_app: :farmbot
  end

  plug Plug.Static, from: {:farmbot, "priv/static"}, at: "/"
  plug Plug.Logger, log: :debug
  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug :match
  plug :dispatch

  require Logger
  alias Farmbot.System.ConfigStorage

  get "/", do: render_page(conn, "index")

  get "/network" do
    interfaces = Nerves.NetworkInterface.interfaces()
    info = [interfaces: Map.new(interfaces, fn(iface) ->
      if String.first(iface) == "w" do
        {iface, %{type: :wireless, ssids: do_iw_scan(iface)}}
      else
        {iface, %{type: :wired}}
      end
    end)]
    render_page(conn, "network", info)
  end

    defp do_iw_scan(iface) do
    case System.cmd("iw", [iface, "scan", "ap-force"]) do
      {res, 0} -> res |> clean_ssid
      e -> raise "Could not scan for wifi: #{inspect e}"
    end
  end

  defp clean_ssid(hc) do
    hc
    |> String.replace("\t", "")
    |> String.replace("\\x00", "")
    |> String.split("\n")
    |> Enum.filter(fn(s) -> String.contains?(s, "SSID: ") end)
    |> Enum.map(fn(z)    -> String.replace(z, "SSID: ", "") end)
    |> Enum.filter(fn(z) -> String.length(z) != 0 end)
  end

  get "/firmware" do
    render_page(conn, "firmware")
  end

  get "/credentials" do
    email  = ConfigStorage.get_config_value(:string, "authorization", "email")    || ""
    pass   = ConfigStorage.get_config_value(:string, "authorization", "password") || ""
    server = ConfigStorage.get_config_value(:string, "authorization", "server")   || ""
    ConfigStorage.update_config_value(:string, "authorization", "token",    nil)
    render_page(conn, "credentials", [server: server, email: email, password: pass])
  end

  post "/configure_network" do
    {:ok, _, conn} = read_body conn
    :ok = conn.body_params |> sort_network_configs |> input_network_configs

    redir(conn, "/firmware")
  end

  defp sort_network_configs(map, acc \\ %{})

  defp sort_network_configs(map, acc) when is_map(map) do
    sort_network_configs(Map.to_list(map), acc)
  end

  defp sort_network_configs([{key, val} | rest], acc) do
    [iface, key] = String.split(key, "_")
    acc = case acc[iface] do
      map when is_map(map) -> %{acc | iface => Map.merge(acc[iface], %{key => val})}
      nil -> Map.put(acc, iface, %{key => val})
    end

    sort_network_configs(rest, acc)
  end

  defp sort_network_configs([], acc), do: acc

  defp input_network_configs(conf_map)

  defp input_network_configs(conf_map) when is_map(conf_map) do
    conf_map |> Map.to_list() |> input_network_configs
  end

  defp input_network_configs([{iface,  settings} | rest]) do
    if settings["enable"] == "on" do
      Logger.info "inputting #{iface} - #{inspect settings}"
      case settings["type"] do
        "wireless" ->
          %ConfigStorage.NetworkInterface{
            name: iface,
            type: "wireless",
            ssid: Map.fetch!(settings, "ssid"),
            psk: Map.fetch!(settings, "psk"),
            security: "WPA-PSK",
            ipv4_method: "dhcp"
          }
        "wired" ->
          %ConfigStorage.NetworkInterface{name: iface,
            type: "wired",
            ipv4_method: "dhcp"
          }
      end
      |> ConfigStorage.insert!()
    end
    input_network_configs(rest)
  end

  defp input_network_configs([]) do
    :ok
  end

  post "/configure_firmware" do
    {:ok, _, conn} = read_body conn
    case conn.body_params do
      %{"firmware_hardware" => hw} when hw in ["arduino", "farmduino"] ->
        ConfigStorage.update_config_value(:string, "hardware", "firmware_hardware", hw)
        #TODO Flash firmware here.
        redir(conn, "/credentials")
      %{"firmware_hardware" => "custom"} ->
        ConfigStorage.update_config_value(:string, "hardware", "firmware_hardware", "custom")
        redir(conn, "/credentials")
      _ ->  send_resp(conn, 500, "Bad firmware_hardware!")
    end
  end

  post "/configure_credentials" do
    {:ok, _, conn} = read_body conn
    case conn.body_params do
      %{"email" => email, "password" => pass, "server" => server} ->
        ConfigStorage.update_config_value(:string, "authorization", "email",    email)
        ConfigStorage.update_config_value(:string, "authorization", "password", pass)
        ConfigStorage.update_config_value(:string, "authorization", "server",   server)
        ConfigStorage.update_config_value(:string, "authorization", "token",    nil)
        render_page(conn, "finish")
      _ -> send_resp(conn, 500, "invalid request.")
    end
  end

  match _, do: send_resp(conn, 404, "Page not found")

  defp redir(conn, loc) do
    conn
    |> put_resp_header("location", loc)
    |> send_resp(302, loc)
  end

  defp render_page(conn, page, info \\ []) do
    page
    |> template_file()
    |> EEx.eval_file(info)
    |> fn(contents) -> send_resp(conn, 200, contents) end.()
  rescue
    e -> send_resp(conn, 500, "Failed to render page: #{page} inspect: #{Exception.message(e)}")
  end

  defp template_file(file) do
    "#{:code.priv_dir(:farmbot)}/static/templates/#{file}.html.eex"
  end
end
