defmodule Plug.Streamer do
  alias Plug.Conn
  import Conn
  @behaviour Plug
  @boundry "w58EW1cEpjzydSCq"

  def init(opts), do: opts

  def call(conn, _opts) do
    conn = put_resp_header(conn, "content-type", "multipart/x-mixed-replace; boundary=#{@boundry}")
    conn = send_chunked(conn, 200)
    send_picture(conn)
    conn
  end

  defp send_picture(conn) do
    file = Farmbot.Camera.capture("/tmp/stream.jpg", ["-q"])
    Process.sleep(5)
    size = byte_size(file)
    header = "------#{@boundry}\r\nContent-Type: \"image/jpeg\"\r\nContent-length: #{size}\r\n\r\n"
    footer = "\r\n"
    with {:ok, conn} <- chunk(conn, header),
         {:ok, conn} <- chunk(conn, file),
         {:ok, conn} <- chunk(conn, footer), do: send_picture(conn)
    conn
  end
end

defmodule Farmbot.Configurator.Streamer do
  @moduledoc false
  require Logger
  use Plug.Router
  plug Plug.Logger
  plug Plug.Streamer
  plug :match
  plug :dispatch
  match _, do: conn
end
