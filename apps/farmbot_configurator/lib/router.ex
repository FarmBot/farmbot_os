defmodule Farmbot.Configurator.Router do
  @moduledoc """
    Routes incoming connections.
  """
  alias Farmbot.System.FS.ConfigStorage
  alias Farmbot.System.Network, as: NetMan
  require Logger

  use Plug.Router
  # this is so we can serve the bundle.js file.
  plug Plug.Static, at: "/", from: :farmbot_configurator
  plug :match
  plug :dispatch
  plug CORSPlug

  get "/", do: conn |> send_resp(200, make_html())

  get "/api/config" do
    # Already in json form.
    {:ok, config} = ConfigStorage.read_config_file
    conn |> send_resp(200, config)
  end

  post "/api/config" do
    {:ok, body, _} = read_body(conn)
    rbody = Poison.decode!(body)
    # TODO THIS NEEDS SOME HARD CHECKING. PROBABLY IN THE CONFIG STORAGE MODULE
    ConfigStorage.replace_config_file(rbody)
    conn |> send_resp(200,body)
  end

  post "/api/config/creds" do
    {:ok, body, _} = read_body(conn)
    %{"email" => email,"pass" => pass,"server" => server} = Poison.decode!(body)
    Farmbot.Auth.interim(email, pass, server)
    conn |> send_resp(200, "ok")
  end

  get "/api/network/scan" do
    {:ok, body, _} = read_body(conn)
    %{"iface" => iface} = Poison.decode!(body)
    scan = NetMan.scan(iface)
    case scan do
      {:error, reason} -> conn |> send_resp(500, "could not scan: #{inspect reason}")
      ssids -> conn |> send_resp(200, Poison.encode!(ssids))
    end
  end

  post "/api/factory_reset" do
    Logger.debug "goodbye."
    spawn fn() ->
      # sleep to allow the request to finish.
      Process.sleep(100)
      Farmbot.System.factory_reset
    end
    conn |> send_resp(204, "GoodByeWorld!")
  end

  post "/api/try_log_in" do
    Logger.debug "Trying to log in. "
    spawn fn() ->
      # sleep to allow the request to finish.
      Process.sleep(100)
      Logger.debug "THAT ISNT WORKINGF YET!!!"
    end
    conn |> send_resp(200, "OK")
  end

  # anything that doesn't match a rest end point gets the index.
  match _, do: conn |> send_resp(404, "not found")

  def make_html do
    "#{:code.priv_dir(:farmbot_configurator)}/static/index.html" |> File.read!
  end
end
