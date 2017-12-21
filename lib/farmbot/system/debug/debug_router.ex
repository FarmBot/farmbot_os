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
