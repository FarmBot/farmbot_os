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

  get "/", do: render_page(conn, "index")

  get "/network" do
    info = [interfaces: %{eth0: %{type: :wired}, wlan0: %{type: :wireless, ssids: ["hello", "world"]}}]
    render_page(conn, "network", info)
  end

  get "/firmware" do
    render_page(conn, "firmware")
  end

  post "/configure_network" do
    {:ok, _, conn} = read_body conn
    sorted = conn.body_params |> sort_network_configs
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
