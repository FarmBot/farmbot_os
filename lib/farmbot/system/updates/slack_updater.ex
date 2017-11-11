defmodule Farmbot.System.Updates.SlackUpdater do
  @moduledoc """
  Development module for auto flashing fw updates.
  """

  @token System.get_env("SLACK_TOKEN")
  @target Mix.Project.config()[:target]

  use Farmbot.Logger
  use GenServer

  defmodule RTMSocket do
    @moduledoc false
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
      case socket |> Socket.Web.recv!() do
        {:text, data} -> data |> Poison.decode!() |> handle_data(socket, cb)
        {:ping, _} -> Socket.Web.send!(socket, {:pong, ""})
      end

      receive do
        {:stop, _reason} ->
          term_msg =
            %{
              type: "message",
              id: 2,
              channel: "C58DCU4A3",
              text: ":farmbot-genesis: #{node()} Disconnected!"
            }
            |> Poison.encode!()

          Socket.Web.send!(socket, {:text, term_msg})
          Socket.Web.close(socket)

        data ->
          Socket.Web.send!(socket, {:text, Poison.encode!(data)})
          socket_loop(socket, cb)
      after
        500 -> socket_loop(socket, cb)
      end
    end

    defp handle_data(%{"type" => "hello"}, socket, _) do
      Logger.success(3, "Connected to slack!")

      msg =
        %{
          type: "message",
          id: 1,
          channel: "C58DCU4A3",
          text: ":farmbot-genesis: #{node()} Connected!"
        }
        |> Poison.encode!()

      Socket.Web.send!(socket, {:text, msg})
    end

    defp handle_data(msg, _socket, cb), do: send(cb, {:socket, msg})
  end

  def start_link() do
    GenServer.start_link(__MODULE__, @token, name: __MODULE__)
  end

  def init(nil) do
    Logger.warn(3, "Not setting up slack.")
    :ignore
  end

  def init(token) do
    url = "https://slack.com/api/rtm.connect"
    payload = {:multipart, [{"token", token}]}
    headers = [{'User-Agent', 'Farmbot HTTP Adapter'}]

    case HTTPoison.post(url, payload, headers) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, rtm_socket} =
          body
          |> Poison.decode!()
          |> ensure_good_login
          |> Map.get("url")
          |> RTMSocket.start_link(self())

        {:ok, %{rtm_socket: rtm_socket, token: token}}

      err ->
        Logger.error(3, "Failed to get RTM Auth: #{inspect(err)}")
        :ignore
    end
  end

  defp ensure_good_login(%{"ok" => true} = msg), do: msg

  defp ensure_good_login(msg) do
    raise("failed to auth: #{inspect(msg)}")
  end

  def handle_info({:socket, %{"file" => %{ "url_private_download" => dl_url, "name" => name}}}, state) do
    if Path.extname(name) == ".fw" do
      if match?(<<@target, <<"-">>, _rest :: binary>>, name) do
        Logger.warn(3, "Downloading and applying an image from slack!")
        path = Farmbot.HTTP.download_file(dl_url, "/tmp/#{name}", [], [{'Authorization', 'Bearer #{state.token}'}])
        Nerves.Firmware.upgrade_and_finalize(path)
        Farmbot.System.reboot("Slack update.")
        {:stop, :normal, state}
      else
        Logger.debug(3, "Not downloading #{name} (wrong target)")
        {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end

  def handle_info({:socket, _msg}, state) do
    # Logger.debug 2, "got message: #{inspect msg}"
    {:noreply, state}
  end

  def terminate(reason, state) do
    send(state.rtm_socket, {:stop, reason})
  end
end
