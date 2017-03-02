defmodule Farmbot.Configurator.Router do
  @moduledoc """
    Routes incoming connections.
  """
  alias Farmbot.System.FS.ConfigStorage
  alias Farmbot.System.Network, as: NetMan
  require Logger

  use Plug.Router
  # plug Plug.Logger
  # this is so we can serve the bundle.js file.
  plug Plug.Static, at: "/", from: :farmbot
  plug Plug.Static, at: "/image", from: "/tmp/images", gzip: false
  plug :match
  plug :dispatch
  plug CORSPlug

  get "/image/latest" do
    list_images = fn() ->
      "/tmp/images"
      |> File.ls!
      |> Enum.reduce("", fn(image, acc) ->
        acc <> "<img src=\"/image/#{image}\">"
      end)
    end
    html =
      ~s"""
      <html>
        <body>
          <form action=/image/capture>
            <input type="submit" value="Capture">
          </form>
          #{list_images.()}
        </body>
      </html>
      """
    conn |> send_resp(200, html)
  end

  get "/image/capture" do
    Farmbot.Camera.capture()
    conn
    |> put_resp_header("location", "/image/latest")
    |> send_resp(302, "OK")
  end

  get "/", do: conn |> send_resp(200, make_html())
  get "/setup" do
    conn
    |> put_resp_header("location", "http://192.168.24.1/index.html")
    |> send_resp(302, "OK")
  end

  get "/api/config" do
    # Already in json form.
    {:ok, config} = ConfigStorage.read_config_file
    conn |> send_resp(200, config)
  end

  post "/api/config" do
    Logger.info ">> router got config json"
    {:ok, body, _} = read_body(conn)
    rbody = Poison.decode!(body)
    # TODO THIS NEEDS SOME HARD CHECKING. PROBABLY IN THE CONFIG STORAGE MODULE
    ConfigStorage.replace_config_file(rbody)
    conn |> send_resp(200,body)
  end

  post "/api/config/creds" do
    Logger.info ">> router got credentials"
    {:ok, body, _} = read_body(conn)
    %{"email" => email,"pass" => pass,"server" => server} = Poison.decode!(body)
    Farmbot.Auth.interim(email, pass, server)
    conn |> send_resp(200, "ok")
  end

  post "/api/network/scan" do
    {:ok, body, _} = read_body(conn)
    %{"iface" => iface} = Poison.decode!(body)
    scan = NetMan.scan(iface)
    case scan do
      {:error, reason} -> conn |> send_resp(500, "could not scan: #{inspect reason}")
      ssids -> conn |> send_resp(200, Poison.encode!(ssids))
    end
  end

  get "/api/network/interfaces" do
    blah = Farmbot.System.Network.enumerate
    case Poison.encode(blah) do
      {:ok, interfaces} ->
        conn |> send_resp(200, interfaces)
      {:error, reason} ->
        conn |> send_resp(500, "could not enumerate interfaces: #{inspect reason}")
      error ->
        conn |> send_resp(500, "could not enumerate interfaces: #{inspect error}")
    end
  end

  post "/api/factory_reset" do
    Logger.info "goodbye."
    spawn fn() ->
      # sleep to allow the request to finish.
      Process.sleep(100)
      Farmbot.System.factory_reset
    end
    conn |> send_resp(204, "GoodByeWorld!")
  end

  post "/api/try_log_in" do
    Logger.info "Trying to log in. "
    spawn fn() ->
      # sleep to allow the request to finish.
      Process.sleep(100)

      # restart network.
      # not going to bother checking if it worked or not, (at least until i
      # reimplement networking) because its so fragile.
      Farmbot.System.Network.restart
    end
    conn |> send_resp(200, "OK")
  end

  get "/api/logs" do
    logs = GenEvent.call(Logger, Farmbot.Logger, :messages)

    only_messages = Enum.map(logs, fn(log) ->
      log.message
    end)
    json = Poison.encode!(only_messages)
    conn |> send_resp(200, json)
  end

  get "/api/state" do
    Farmbot.BotState.Monitor.get_state
     state = Farmbot.Transport.get_state
     json = Poison.encode!(state)
     conn |> send_resp(200, json)
  end

  # anything that doesn't match a rest end point gets the index.
  match _, do: conn |> send_resp(404, "not found")

  @spec make_html :: binary
  defp make_html do
    "#{:code.priv_dir(:farmbot)}/static/index.html" |> File.read!
  end
end
