defmodule Farmbot.System.Updates.SlackUpdater do
  @moduledoc """
  Development module for auto flashing fw updates.
  """

  @token System.get_env("SLACK_TOKEN")
  @target Farmbot.Project.target()
  @data_path Application.get_env(:farmbot, :data_path)

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
        {:stop, reason} ->
          term_msg =
            %{
              type: "message",
              id: 2,
              channel: "C58DCU4A3",
              text: ":farmbot-genesis: #{node()} Disconnected (#{inspect(reason)})"
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

  def upload_file(file, channels \\ "C58DCU4A3") do
    GenServer.call(__MODULE__, {:upload_file, file, channels}, :infinity)
  end

  def start_link() do
    GenServer.start_link(__MODULE__, @token, name: __MODULE__)
  end

  def init(nil) do
    Logger.warn(3, "Not setting up slack (No slack token)")
    :ignore
  end

  def init(token) do
    url = "https://slack.com/api/rtm.connect"
    payload = {:multipart, [{"token", token}]}
    headers = [{'User-Agent', 'Farmbot HTTP Adapter'}]

    with {:ok, %{status_code: 200, body: body}} <- HTTPoison.post(url, payload, headers),
         {:ok, %{"ok" => true} = results} <- Poison.decode(body),
         {:ok, url} <- Map.fetch(results, "url"),
         {:ok, pid} <- RTMSocket.start_link(url, self()) do
      Process.link(pid)
      {:ok, %{rtm_socket: pid, token: token, updating: false}}
    else
      {:error, :invalid, _} ->
        init(token)

      {:ok, %{status_code: code}} ->
        Logger.error(2, "Failed get RTM Auth: #{code}")
        :ignore

      {:error, reason} ->
        Logger.error(2, "Failed to get RTM Auth: #{inspect(reason)}")
        :ignore
    end
  end

  def handle_call({:upload_file, file, channels}, _from, state) do
    file = to_string(file)

    payload =
      %{
        :file => file,
        "token" => state.token,
        "channels" => channels,
        "title" => file,
        "initial_comment" => ""
      }
      |> Map.to_list()

    real_payload = {:multipart, payload}
    url = "https://slack.com/api/files.upload"
    headers = [{'User-Agent', 'Farmbot HTTP Adapter'}]

    case HTTPoison.post(url, real_payload, headers, follow_redirect: true) do
      {:ok, %{status_code: code, body: body}} when code > 199 and code < 300 ->
        if Poison.decode!(body) |> Map.get("ok", false) do
          :ok
        else
          Logger.error(3, "#{inspect(Poison.decode!(body, pretty: true))}")
        end

      other ->
        Logger.error(3, "#{inspect(other)}")
    end

    {:reply, :ok, state}
  end

  def handle_info(
        {:socket, %{"file" => %{"url_private_download" => dl_url, "name" => name}}},
        state
      ) do
    if Path.extname(name) == ".fw" do
      if match?(<<(<<"farmbot-">>), @target, <<"-">>, _rest::binary>>, name) do
        Logger.warn(3, "Downloading and applying an image from slack!")

        if Farmbot.System.ConfigStorage.get_config_value(:bool, "settings", "os_auto_update") do
          dl_fun = Farmbot.BotState.download_progress_fun("FBOS_OTA")

          case Farmbot.HTTP.download_file(dl_url, Path.join(@data_path, name), dl_fun, "", [
                 {'Authorization', 'Bearer #{state.token}'}
               ]) do
            {:ok, path} ->
              Farmbot.System.Updates.apply_firmware(path, true)
              {:stop, :normal, %{state | updating: true}}

            {:error, reason} ->
              Logger.error(3, "Failed to download update file: #{inspect(reason)}")
              {:noreply, state}
          end
        else
          Logger.warn(3, "Not downloading debug update because auto updates are disabled.")
          {:noreply, state}
        end
      else
        Logger.debug(3, "Not downloading #{name} (wrong target)")
        {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end

  def handle_info({:socket, _msg}, state), do: {:noreply, state}

  def terminate(reason, state) do
    if Process.alive?(state.rtm_socket) do
      send(state.rtm_socket, {:stop, reason})
    end
  end
end
