defmodule Farmbot.System.DebugRouter do
  @moduledoc false

  use Plug.Router
  use Farmbot.Logger

  # max length of a uploaded file.
  @max_length 111_409_842

  use Plug.Debugger, otp_app: :farmbot
  plug(Plug.Logger, log: :debug)

  plug(
    Plug.Parsers,
    length: @max_length,
    parsers: [:urlencoded, :multipart, :json],
    json_decoder: Poison
  )

  plug(Plug.Static, from: {:farmbot, "priv/debug/static"}, at: "/")
  plug(CORSPlug)
  plug(:match)
  plug(:dispatch)

  forward("/wobserver", to: Wobserver.Web.Router)

  get "/" do
    conn |> send_resp(200, make_html("index"))
  end

  get "/firmware/upload" do
    conn |> send_resp(200, make_html("firmware_upload"))
  end

  post "/api/upload_firmware" do
    ml = @max_length
    {:ok, _body, conn} = Plug.Conn.read_body(conn, length: ml)

    upload =
      case conn.body_params do
        %{"file" => upload} -> upload
        %{"firmware" => upload} -> upload
      end

    file = upload.path

    case Path.extname(upload.filename) do
      ".hex" ->
        Logger.warn(1, "applying debug arduino/farmduino firmware.")
        handle_arduino(file, conn)

      ".fw" ->
        Logger.warn(1, "applying debug os firmware.")
        handle_os(file, conn)

      _ ->
        conn |> send_resp(500, "COULD NOT HANDLE #{upload.filename}")
    end
  end

  get "/api/release_mock.json" do
    file = "#{:code.priv_dir(:farmbot)}/debug/templates/release_mock.json.eex"

    url = "http://#{conn.host}:#{conn.port}/api/release_mock.json"
    tag_name = conn.params["tag_name"] || "v#{Farmbot.Project.version()}"
    target_commitish = conn.params["target_commitish"] || Farmbot.Project.commit
    body = conn.params["body"] || "This is a fake release"

    File.cp "_build/rpi3/prod/nerves/images/farmbot-signed.fw", "#{:code.priv_dir(:farmbot)}/debug/static/farmbot-rpi3-#{tag_name}.fw"
    fw_asset_url = conn.params["fw_asset_url"] || "http://#{conn.host}:#{conn.port}/farmbot-rpi3-#{tag_name}.fw"
    resp = EEx.eval_file(file, [url: url, fw_asset_url: fw_asset_url, tag_name: tag_name, target_commitish: target_commitish, body: body])
    conn
    |> put_resp_header("content-type", "Application/JSON")
    |> send_resp(200, resp)
  end

  match(_, do: send_resp(conn, 404, "Page not found"))

  defp make_html(file) do
    "#{:code.priv_dir(:farmbot)}/debug/static/#{file}.html" |> File.read!()
  end

  defp handle_arduino(_, conn) do
    send_resp(conn, 500, "Not implemented.")
  end

  defp handle_os(file, conn) do
    case Nerves.Firmware.upgrade_and_finalize(file) do
      {:error, reason} ->
        conn |> send_resp(400, inspect(reason))

      :ok ->
        conn = send_resp(conn, 200, "UPGRADING")
        Process.sleep(2000)
        Nerves.Firmware.reboot()
        conn
    end
  end
end
