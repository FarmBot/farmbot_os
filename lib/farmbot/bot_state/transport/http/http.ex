defmodule Farmbot.BotState.Transport.HTTP do
  @moduledoc """
  RESTful API for accessing internal Farmbot state.

  # Accessing the API
  A developer should be able to access the REST API at
  `http://<my_farmbot_id>:27347/api/v1/`. The calls will require an authentication token.
  See the [API docs](https://github.com/farmbot/Farmbot-Web-App#q-how-can-i-generate-an-api-token)
  for information about generating a token. Access to the local api should be
  the same as accessing the cloud API. You will need to have an HTTP header:
  `Authorization`:`Bearer <long encrypted token>`

  Each of the routes will be described below.

  * GET `/api/v1/bot/state` - returns the bot's current state.
  """

  use GenStage
  alias Farmbot.BotState.Transport.HTTP.{Router, SocketHandler}

  @port 27347

  @doc "Subscribe to events."
  def subscribe do
    GenStage.call(__MODULE__, :subscribe)
  end

  @doc "Unsubscribe."
  def unsubscribe do
    GenStage.call(__MODULE__, :unsubscribe)
  end

  def public_key do
    GenStage.call(__MODULE__, :public_key)
  end

  @doc false
  def start_link do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    s = Farmbot.System.ConfigStorage.get_config_value(:string, "authorization", "server")
    {:ok, {_, _, body}} = :httpc.request(:get, {'#{s}/api/public_key', []}, [], [body_format: :binary])
    public_key = body |> JOSE.JWK.from_pem
    state = %{bot_state: nil, sockets: [], public_key: public_key}
    {:ok, web} = Plug.Adapters.Cowboy.http Router, [], [port: @port, dispatch: [cowboy_dispatch()]]
    Process.link(web)
    {:consumer, state, [subscribe_to: [Farmbot.BotState, Farmbot.Logger]]}
  end

  def handle_events(events, {pid, _}, state) do
    dispatch Process.info(pid)[:registered_name], events, state
  end

  def handle_call(:subscribe, {pid, _ref}, state) do
    {:reply, :ok, [], %{state | sockets: [pid | state.sockets]}}
  end

  def handle_call(:unsubscribe, {pid, _ref}, state) do
    {:reply, :ok, [], %{state | sockets: List.delete(state.sockets, pid)}}
  end

  def handle_call(:public_key, _, state) do
    {:reply, {:ok, state.public_key}, [], state}
  end

  defp dispatch(Farmbot.BotState = dispatcher, events, %{sockets: sockets} = state) do
    bot_state = List.last(events)
    for socket <- sockets do
      send socket, {dispatcher, bot_state}
    end
    {:noreply, [], %{state | bot_state: bot_state }}
  end

  defp dispatch(Farmbot.Logger = dispatcher, logs, %{sockets: sockets} = state) do
    for socket <- sockets do
      send socket, {dispatcher, logs}
    end
    {:noreply, [], state}
  end

  defp cowboy_dispatch do
    {:_,
      [
        {"/ws", SocketHandler, []},
        {:_, Plug.Adapters.Cowboy.Handler, {Router, []}},
      ]
    }
  end
end
