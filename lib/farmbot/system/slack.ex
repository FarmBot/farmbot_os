defmodule Farmbot.System.NervesCommon.Updates.Slack do
  @moduledoc """
  Development module for auto flashing fw updates.
  """

  require Logger
  use GenServer
  alias Farmbot.{Context, HTTP, DebugLog}
  use DebugLog

  defmodule RTMSocket do
    def start_link(url, cb) do
      pid = spawn(__MODULE__, :socket_init, [url, cb])
      {:ok, pid}
    end

    def socket_init("wss://" <> url, cb) do
      [domain | rest] = String.split(url, "/")
      domain
      |> Socket.Web.connect!(secure: true, path: "/" <> Enum.join(rest, "/"))
      |> socket_loop(cb)
    end

    def socket_init("ws://" <> url, cb) do
      [domain | rest] = String.split(url, "/")
      domain
      |> Socket.Web.connect!(secure: false, path: "/" <> Enum.join(rest, "/"))
      |> socket_loop(cb)
    end

    defp socket_loop(socket, cb) do
      case socket |> Socket.Web.recv! do
        {:text, data} -> data |> Poison.decode! |> handle_data(socket, cb)
        {:ping, _}    -> Socket.Web.send!(socket, {:pong, ""})
      end

      receive do
        {:stop, _reason} ->
          term_msg = %{
            type: "message",
            id: 2,
            channel: "C58DCU4A3",
            text: ":farmbot-genesis: #{node()} Disconnected!"
          } |> Poison.encode!
          Socket.Web.send!(socket, {:text, term_msg})
          Socket.Web.close(socket)
        data  ->
          Socket.Web.send!(socket, {:text, Poison.encode!(data)})
          socket_loop(socket, cb)
      after 500 -> socket_loop(socket, cb)
      end
    end

    defp handle_data(%{"type" => "hello"}, socket, _) do
      Logger.info ">> is connected to slack!", type: :success
      msg = %{
        type: "message",
        id: 1,
        channel: "C58DCU4A3",
        text: ":farmbot-genesis: #{node()} Connected!"
      } |> Poison.encode!()
      Socket.Web.send!(socket, {:text, msg})
    end

    defp handle_data(msg, _socket, cb), do: send(cb, {:socket, msg})
  end

  @token System.get_env("SLACK_TOKEN")

  def start_link(%Context{} = context, opts \\ []) do
    GenServer.start_link(__MODULE__, {context, @token}, opts)
  end

  def init({_, nil}) do
    :ignore
  end

  def init({context, token}) do
    debug_log "Using token: #{token}"
    url     = "https://slack.com/api/rtm.connect"
    payload = {:multipart, [{"token", token}]}
    headers = [{'User-Agent', 'Farmbot HTTP Adapter'}]
    case HTTP.post(context, url, payload, headers) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, rtm_socket} =
          body
          |> Poison.decode!
          |> ensure_good_login
          |> Map.get("url")
          |> RTMSocket.start_link(self())
        {:ok, %{rtm_socket: rtm_socket, context: context, token: token}}
      err ->
        debug_log "Failed to get RTM Auth: #{inspect err}"
        :ignore
    end
  end

  defp ensure_good_login(%{"ok" => true} = msg), do: msg
  defp ensure_good_login(msg) do
    raise("failed to auth: #{inspect msg}")
  end

  def handle_info({:socket, %{"channel" => "C41SHHGQ5",
                              "file"    => %{"url_private_download" => dl_url,
                                             "name"                 => name,
                                             "channels"             => ["C41SHHGQ5"],
                                           }
                            }
                  } = msg, state)
  do
    if Path.extname(name) == ".fw" do
      Logger.info ">> is downloading and applying an immage from slack!", type: :busy
      path = HTTP.download_file!(state.context, dl_url, "/tmp/#{name}", [], [{'Authorization', 'Bearer #{state.token}'}])
      Farmbot.System.Updates.setup_post_update()
      Nerves.Firmware.upgrade_and_finalize(path)
      Farmbot.System.reboot()
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  def handle_info({:socket, _msg}, state) do
    {:noreply, state}
  end

  def terminate(reason, state) do
    send state.rtm_socket, {:stop, reason}
  end
end
