defmodule Farmbot.BotState.Transport.HTTP do
  @moduledoc "Transport for accepting CS and pushing state over HTTP."
  use GenStage
  require Logger
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
